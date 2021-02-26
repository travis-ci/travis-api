require 'addressable/uri'
require 'faraday'
require 'faraday_middleware'
require 'securerandom'
require 'travis/api/app'
require 'travis/remote_vcs/user'
require 'travis/remote_vcs/response_error'
require 'uri'

class Travis::Api::App
  class Endpoint
    # You need to get hold of an access token in order to reach any
    # endpoint requiring authorization.
    # There are three ways to get hold of such a token: OAuth2, via a GitHub
    # token you may already have or with Cross-Origin Window Messages.
    #
    # ## OAuth2
    #
    # API authorization is done via a subset of OAuth2 and is largely compatible
    # with the [GitHub process](http://developer.github.com/v3/oauth/).
    # Be aware that Travis CI will in turn use OAuth2 to authenticate (and
    # authorize) against GitHub.
    #
    # This is the recommended way for third-party web apps.
    # The entry point is [/auth/authorize](#/auth/authorize).
    #
    # ## GitHub Token
    #
    # If you already have a GitHub token with the same or greater scope than
    # the tokens used by Travis CI, you can easily exchange it for a access
    # token. Travis will not store the GitHub token and only use it for a single
    # request to resolve the associated user and scopes.
    #
    # This is the recommended way for GitHub applications that also want Travis
    # integration.
    #
    # The entry point is [/auth/github](#POST /auth/github).
    #
    # ## Cross-Origin Window Messages
    #
    # This is the recommended way for the official client. We might improve the
    # authorization flow to support third-party clients in the future, too.
    #
    # The entry point is [/auth/post_message](#/auth/post_message).
    class Authorization < Endpoint
      enable :inline_templates
      set prefix: '/auth'
      set :check_auth, false

      SUSPICIOUS_CODES = ['<', '>']

      # Endpoint for retrieving an authorization code, which in turn can be used
      # to generate an access token.
      #
      # NOTE: This endpoint is not yet implemented.
      #
      # Parameters:
      #
      # * **client_id**: your App's client id (required)
      # * **redirect_uri**: URL to redirect to
      # * **scope**: requested access scope
      # * **state**: should be random string to prevent CSRF attacks
      get '/authorize' do
        raise NotImplementedError
      end

      # Endpoint for generating an access token from an authorization code.
      #
      # NOTE: This endpoint is not yet implemented.
      #
      # Parameters:
      #
      # * **client_id**: your App's client id (required)
      # * **client_secret**: your App's client secret (required)
      # * **code**: code retrieved from redirect from [/auth/authorize](#/auth/authorize) (required)
      # * **redirect_uri**: URL to redirect to
      # * **state**: same value sent to [/auth/authorize](#/auth/authorize)
      post '/access_token' do
        raise NotImplementedError
      end

      # Endpoint for generating an access token from a GitHub access token.
      #
      # Parameters:
      #
      # * **github_token**: GitHub token for checking authorization (required)
      post '/github' do
        unless params[:github_token]
          halt 422, { "error" => "Must pass 'github_token' parameter" }
        end

        # For new provider method
        renew_access_token(token: params[:github_token], app_id: 1, provider: :github)
      end

      # Endpoint for making sure user authorized Travis CI to access VCS provider.
      # There are no restrictions on where to redirect to after handshake.
      # However, no information whatsoever is being sent with the redirect.
      #
      # Parameters:
      #
      # * **redirect_uri**: URI to redirect to after handshake.
      get '/handshake/?:provider?' do
        params[:provider] ||= 'github'
        vcs_handshake do |user, token, redirect_uri|
          if target_ok?(redirect_uri)
            content_type :html
            data = { user: user, token: token, uri: redirect_uri }
            erb(:post_payload, locals: data)
          else
            halt 401, 'target URI not allowed'
          end
        end
      end

      get '/post_message', scope: :public do
        content_type :html
        data = { check_third_party_cookies: !Travis.config.auth.disable_third_party_cookies_check }
        erb(:container, locals: data)
      end

      error Faraday::Error::ClientError do
        halt 401, 'could not resolve github token'
      end

      get '/confirm_user/:token' do
        Travis::RemoteVCS::User.new.confirm_user(token: params[:token])
      rescue Travis::RemoteVCS::ResponseError
        halt 404, 'The token is expired or not found.'
      end

      get '/request_confirmation/:session_token/:id' do
        Travis::RemoteVCS::User
          .new.request_confirmation(session_token: params[:session_token], id: params[:id])
      end

      private

        # update first login date if not set
        def update_first_login(user)
          unless user.first_logged_in_at
            user.update_attributes(first_logged_in_at: Time.now)
          end
        end

        def serialize_user(user)
          rendered = Travis::Api::Serialize.data(user, version: :v2)
          rendered['user'].merge('token' => user.tokens.first.try(:token).to_s)
        end

        def oauth_endpoint
          proxy = Travis.config.oauth2.proxy
          proxy ? File.join(proxy, request.fullpath) : (ENV['AUTH_HANDSHAKE_HOST'] || url)
        end

        def log_with_request_id(line)
          request_id = request.env["HTTP_X_REQUEST_ID"]
          Travis.logger.info "#{line} <request_id=#{request_id}>"
        end

        # VCS HANDSHAKE START

        def remote_vcs_user
          @remote_vcs_user ||= Travis::RemoteVCS::User.new
        end

        def vcs_handshake
          if params[:code]
            unless state_ok?(params[:state], params[:provider])
              handle_invalid_response
              return
            end

            vcs_data = remote_vcs_user.authenticate(
              provider: params[:provider],
              code: params[:code],
              redirect_uri: oauth_endpoint
            )

            if vcs_data['redirect_uri'].present?
              redirect to(vcs_data['redirect_uri'])
              return
            end

            user = User.find(vcs_data['user']['id'])
            update_first_login(user)
            yield serialize_user(user), vcs_data['token'], payload(params[:provider])
          else
            state = vcs_create_state(params[:origin] || params[:redirect_uri])

            vcs_data = remote_vcs_user.auth_request(
              provider: params[:provider],
              state: state,
              redirect_uri: oauth_endpoint
            )

            response.set_cookie(cookie_name(params[:provider]), value: state, httponly: true)
            redirect to(vcs_data['authorize_url'])
          end
        rescue ::Travis::RemoteVCS::ResponseError
          halt 401, "Can't login"
        end

        def renew_access_token(token:, app_id:, provider:)
          vcs_data = remote_vcs_user.generate_token(
            provider: provider,
            token: token,
            app_id: app_id
          )

          if vcs_data['redirect_uri']
            redirect to(vcs_data['redirect_uri'])
          else
            { access_token: vcs_data['token'] }
          end
        rescue ::Travis::RemoteVCS::ResponseError
          halt 401, "Can't renew token"
        end

        def vcs_create_state(payload)
          state = SecureRandom.urlsafe_base64(16)
          state << ":::" << payload if payload
          state
        end

        def payload(provider)
          request.cookies[cookie_name(provider)].split(':::').last
        end

        def cookie_name(provider = :github)
          "travis.state-#{provider}"
        end

        # VCS HANDSHAKE END

        def clear_state_cookies
          response.delete_cookie cookie_name(:github)
          response.delete_cookie cookie_name(:gitlab)
          response.delete_cookie cookie_name(:bitbucket)
          response.delete_cookie cookie_name(:assembla)
        end

        def handle_invalid_response
          clear_state_cookies
          redirect to("https://#{Travis.config.host}/")
        end

        def state_ok?(state, provider = :github)
          cookie_state = request.cookies[cookie_name(provider)]
          state == cookie_state and redis.srem('github:states', state.to_s.split(":::", 1))
        end

        def post_message(payload)
          content_type :html
          erb(:post_message, locals: payload)
        end

        def invalid_target(target_origin)
          content_type :html
          erb(:invalid_target, {}, target_origin: target_origin)
        end

        def target_ok?(target_origin)
          test_target_origin = URI.decode(target_origin).downcase
          return if SUSPICIOUS_CODES.any? { |word| test_target_origin.include?(word) }
          return unless uri = Addressable::URI.parse(target_origin)
          if allowed_https_targets.include?(uri.host)
            uri.scheme == 'https'
          elsif uri.host =~ /\A(.+\.)?travis-ci\.(com|org)\Z/
            uri.scheme == 'https'
          elsif uri.host == 'localhost' or uri.host == '127.0.0.1'
            uri.inferred_port.to_i > 1023
          end
        end

        def allowed_https_targets
          @allowed_https_targets ||= Travis.config.auth.target_origin.to_s.split(',')
        end

    end
  end
end

__END__

@@ invalid_target
<script>
console.log('refusing to send a token to <%= target_origin.inspect %>, not safelisted!');
</script>

@@ common
function tellEveryone(msg, win) {
  if(win == undefined) win = window;
  win.postMessage(msg, '*');
  if(win.parent != win) tellEveryone(msg, win.parent);
  if(win.opener) tellEveryone(msg, win.opener);
}

@@ container
<!DOCTYPE html>
<html><body><script>
// === THE FLOW ===

// every serious program has a main function
function main() {
  redirect();
}

// === THE LOGIC ===

function redirect() {
  tellEveryone('redirect');
}

// === THE PLUMBING ===
<%= erb :common %>

var succeeded = false;

window.addEventListener("message", function(event) {
  if(event.data === "done") {
    succeeded = true
    for(var i = 0; i < callbacks.length; i++) {
      (callbacks[i])();
    }
  }
});

// === READY? GO! ===
main();
</script>
</body>
</html>

@@ post_message
<script>
<%= erb :common %>
function uberParent(win) {
  return win.parent === win ? win : uberParent(win.parent);
}

function sendPayload(win) {
  var payload = {
    'user': <%= user.to_json %>,
    'token': <%= token.inspect %>
  };
  uberParent(win).postMessage(payload, <%= target_origin.inspect %>);
}

if(window.parent == window) {
  sendPayload(window.opener);
  window.close();
} else {
  tellEveryone('done');
  sendPayload(window.parent);
}
</script>

@@ post_payload
<body onload='document.forms[0].submit()'>
  <form action="<%= uri %>" method='post'>
    <input type='hidden' name='token'   value='<%= token %>'>
    <input type='hidden' name='user'    value="<%= user.to_json.gsub('"', '&quot;') %>">
    <input type='hidden' name='storage' value='localStorage'>
  </form>
</body>
