require 'addressable/uri'
require 'faraday'
require 'faraday_middleware'
require 'securerandom'
require 'travis/api/app'
require 'travis/github/education'
require 'travis/github/oauth'
require 'travis/remote_vcs/user'

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

        renew_access_token(token: params[:github_token], app_id: 1, provider: :github)
      end

      # Endpoint for making sure user authorized Travis CI to access GitHub.
      # There are no restrictions on where to redirect to after handshake.
      # However, no information whatsoever is being sent with the redirect.
      #
      # Parameters:
      #
      # * **redirect_uri**: URI to redirect to after handshake.
      get '/handshake' do
        params[:provider] ||= 'github'
        handshake do |user, token, redirect_uri|
          if target_ok? redirect_uri
            content_type :html
            data = { user: user, token: token, uri: redirect_uri }
            erb(:post_payload, locals: data)
          else
            safe_redirect redirect_uri
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

      private

      def remote_vcs_user
        @remote_vcs_user ||= Travis::RemoteVCS::User.new
      end

      def serialize_user(user)
        rendered = Travis::Api::Serialize.data(user, version: :v2)
        rendered['user'].merge('token' => user.tokens.first.try(:token).to_s)
      end

      def handshake
        if params[:code]
          unless state_ok?(params[:state])
            halt 400, 'state mismatch'
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

          yield serialize_user(User.find(vcs_data['user']['id'])), vcs_data['token'], payload
        else
          state = create_state(params[:origin] || params[:redirect_uri])

          vcs_data = remote_vcs_user.auth_request(
            provider: params[:provider],
            state: state,
            redirect_uri: oauth_endpoint
          )

          response.set_cookie('travis.state', value: state, httponly: true)
          redirect to(vcs_data['authorize_url'])
        end
      end

      def state_ok?(state)
        response.set_cookie('travis.state', '')
        state == request.cookies['travis.state']
      end

      def create_state(payload)
        state = SecureRandom.urlsafe_base64(16)
        state << ":::" << payload if payload
        state
      end

      def payload
        request.cookies['travis.state'].split(':::').last
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
      end

      def oauth_endpoint
        proxy = Travis.config.oauth2.proxy
        proxy ? File.join(proxy, request.fullpath) : url
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
        return unless uri = Addressable::URI.parse(target_origin)

        if allowed_https_targets.include?(uri.host)
          uri.scheme == 'https'
        elsif uri.host =~ /\A(.+\.)?travis-ci\.(com|org)\Z/
          uri.scheme == 'https'
        elsif uri.host == 'localhost' or uri.host == '127.0.0.1'
          uri.port > 1023
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
