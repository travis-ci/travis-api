require 'addressable/uri'
require 'faraday'
require 'securerandom'
require 'travis/api/app'
require 'travis/github/education'
require 'travis/github/oauth'
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
        # renew_access_token(token: params[:github_token], app_id: 1, provider: :github)
        { 'access_token' => github_to_travis(params[:github_token], app_id: 1, drop_token: true) }
      end

      # Endpoint for making sure user authorized Travis CI to access GitHub.
      # There are no restrictions on where to redirect to after handshake.
      # However, no information whatsoever is being sent with the redirect.
      #
      # Parameters:
      #
      # * **redirect_uri**: URI to redirect to after handshake.
      get '/handshake/?:provider?' do
        method = org? ? :handshake : :vcs_handshake
        params[:provider] ||= 'github'
        params[:signup] ||= false
        send(method) do |user, token, redirect_uri|
          if target_ok? redirect_uri
            user[:installation] = params[:installation_id]
            content_type :html
            if params[:setup_action] && params[:setup_action] == 'install' && params[:provider] == 'github'
              redirect_uri = redirect_uri + "?installation_id=#{params[:installation_id]}"
              redirect_uri = "#{Travis.config.vcs_redirects.web_url}#{Travis.config.vcs_redirects[params[:provider]]}?installation_id=#{params[:installation_id]}"
            end
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

      error Faraday::ClientError do
        halt 401, 'could not resolve github token'
      end

      get '/confirm_user/:token' do
        content_type :json
        Travis::RemoteVCS::User.new.confirm_user(token: params[:token])
        { status: 200 }.to_json
      rescue Travis::RemoteVCS::ResponseError
        halt 404, 'The token is expired or not found.'
      end

      get '/request_confirmation/:id' do
        content_type :json
        Travis::RemoteVCS::User
          .new.request_confirmation(id: current_user.id)
        { status: 200 }.to_json
      end

      private

        # update first login date if not set
        def update_first_login(user)
          unless user.first_logged_in_at
            user.update(first_logged_in_at: Time.now)
          end
        end

        def serialize_user(user)
          rendered = Travis::Api::Serialize.data(user, version: :v2)
          token = user.tokens.asset.first.try(:token).to_s
          rendered['user'].merge(
            'token' => token,
            'rss_token' => user.tokens.rss.first.try(:token) || token,
            'web_token' => user.tokens.web.first.try(:token) || token
          )
        end

        def oauth_endpoint
          proxy = Travis.config.oauth2.proxy
          proxy ? File.join(proxy, request.fullpath) : (ENV['AUTH_HANDSHAKE_HOST'] || url)
        end

        def log_with_request_id(line)
          request_id = request.env["HTTP_X_REQUEST_ID"]
          Travis.logger.info "#{line} <request_id=#{request_id}>"
        end

        def handshake
          config   = Travis.config.oauth2.to_h
          endpoint = Addressable::URI.parse(config[:authorization_server])
          values   = {
            client_id:    config[:client_id],
            scope:        config[:scope],
            redirect_uri: oauth_endpoint
          }

          log_with_request_id("[handshake] Starting handshake")

          if params[:code]
            unless state_ok?(params[:state])
              log_with_request_id("[handshake] Handshake failed (state mismatch)")
              handle_invalid_response
              return
            end

            endpoint.path          = config[:access_token_path]
            values[:state]         = params[:state]
            values[:code]          = params[:code]
            values[:client_secret] = config[:client_secret]
            github_token           = get_token(endpoint.to_s, values)
            user                   = user_for_github_token(github_token)
            token                  = generate_token(user: user, app_id: 0)
            payload                = params[:state].split(":::", 2)[1]
            update_first_login(user)
            yield serialize_user(user), token, payload
          else
            values[:state]         = create_state
            endpoint.path          = config[:authorize_path]
            endpoint.query_values  = values
            redirect to(endpoint.to_s)
          end
        end

        # VCS HANDSHAKE START

        def remote_vcs_user
          @remote_vcs_user ||= Travis::RemoteVCS::User.new
        end

        def vcs_handshake
          if params[:code]
            if params[:setup_action] && (params[:setup_action] == 'update' || params[:setup_action] == 'install') && params[:provider] && !params[:state]
              redirect to("#{Travis.config.vcs_redirects.web_url}#{Travis.config.vcs_redirects[params[:provider]]}?installation_id=#{params[:installation_id]}")
            end

            unless state_ok?(params[:state], params[:provider])
              handle_invalid_response
              return
            end

            vcs_data = remote_vcs_user.authenticate(
              provider: params[:provider],
              code: params[:code],
              redirect_uri: oauth_endpoint,
              cluster: params[:cluster]
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
              redirect_uri: oauth_endpoint,
              signup: params[:signup]
            )

            response.set_cookie(cookie_name(params[:provider]), value: state, httponly: true)
            redirect to(vcs_data['authorize_url'])
          end
        rescue ::Travis::RemoteVCS::ResponseError => error
          Travis.logger.error(error.message)

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

        def create_state
          state = SecureRandom.urlsafe_base64(16)
          redis.sadd('github:states', state)
          redis.expire('github:states', 1800)
          payload = params[:origin] || params[:redirect_uri]
          state << ":::" << payload if payload
          response.set_cookie(cookie_name, state)
          state
        end

        def state_ok?(state, provider = :github)
          cookie_state = request.cookies[cookie_name(provider)]
          state == cookie_state and redis.srem('github:states', state.to_s.split(":::", 1))
        end

        def github_to_travis(token, options = {})
          drop_token = options.delete(:drop_token)
          generate_token options.merge(user: user_for_github_token(token, drop_token))
        end

        class UserManager < Struct.new(:data, :token, :drop_token)
          include User::Renaming

          attr_accessor :user

          def initialize(*)
            super

            @user = ::User.find_by_github_id(data['id'])
          end

          def info(attributes = {})
            info = data.to_hash.slice('name', 'login', 'gravatar_id')
            info.merge! attributes.stringify_keys
            if Travis::Features.feature_active?(:education_data_sync) ||
              (user && Travis::Features.owner_active?(:education_data_sync, user))
              info['education'] = education
            end
            info['github_id'] ||= data['id']
            info['vcs_id'] ||= data['id']
            info
          end

          def user_exists?
            user
          end

          def education
            Travis::Github::Education.new(token.to_s).student?
          end

          def fetch
            retried ||= false
            info   = drop_token ? self.info : self.info(github_oauth_token: token)

            ActiveRecord::Base.transaction do
              if user
                ensure_token_is_available
                rename_repos_owner(user.login, info['login'])
                user.update info
              else
                self.user = ::User.create! info
              end

              Travis::Github::Oauth.update_scopes(user) # unless Travis.env == 'test'

              nullify_logins(user.github_id, user.login)
            end

            user
          rescue ActiveRecord::RecordNotUnique
            unless retried
              retried = true
              retry
            end
          end

          def ensure_token_is_available
            unless user.tokens.first
              user.create_a_token
            end
          end
        end

        def user_for_github_token(token, drop_token = false)
          data    = GH.with(token: token.to_s, client_id: nil) { GH['user'] }
          scopes  = parse_scopes data.headers['x-oauth-scopes']
          manager = UserManager.new(data, token, drop_token)

          # The new GitHub fine-grained tokens do not include scopes header yet
          # or any way of retrieving scopes so we just have to assume that
          # user gave all necessary permissions
          # TODO: Remove this when GitHub implements x-oauth-scopes header for
          # fine-grained tokens https://github.com/orgs/community/discussions/36441#discussioncomment-5183431
          scopes = Travis::Github::Oauth.wanted_scopes if github_fine_grained_pat?(token.to_s)

          unless acceptable?(scopes, drop_token)
            # TODO: we should probably only redirect if this is a web
            #      oauth request, are there any other possibilities to
            #      consider?
            url =  Travis.config.oauth2.insufficient_access_redirect_url
            url += "#existing-user" if manager.user_exists?
            redirect to(url)
          end

          user   = manager.fetch
          if user.nil?
            log_with_request_id("[handshake] Fetching user failed")
            halt 403, 'not a Travis user'
          end

          if github_fine_grained_pat?(token.to_s)
            user.github_scopes = Travis::Github::Oauth.wanted_scopes
            user.save!
          end

          Travis.run_service(:sync_user, user)

          user
        rescue GH::Error
          # not a valid token actually, but we don't want to expose that info
          halt 403, 'not a Travis user'
        end

        def github_fine_grained_pat?(token)
          token.start_with?('github_pat_')
        end

        def get_token(endpoint, values)
          # Get base URL for when we setup Faraday since otherwise it'll ignore no_proxy
          url = URI.parse(endpoint)
          base_url = "#{url.scheme}://#{url.host}"
          http_options = {url: base_url, ssl: Travis.config.ssl.to_h.merge(Travis.config.github.ssl || {}).compact}

          conn = Faraday.new(http_options) do |conn|
            conn.request :json
            conn.adapter :net_http_persistent
          end
          response = conn.post(endpoint, values)

          parameters = Addressable::URI.form_unencode(response.body)
          token_info = parameters.assoc("access_token")

          unless token_info
            log_with_request_id("[handshake] Could not fetch token, github's response: status=#{response.status}, body=#{parameters.inspect} headers=#{response.headers.inspect}")
            halt 401, 'could not resolve github token'
          end
          token_info.last
        end

        def parse_scopes(data)
          data.gsub(/\s/,'').split(',') if data
        end

        def generate_token(options)
          AccessToken.create(options).token
        end

        def acceptable?(scopes, lossy = false)
          Travis::Github::Oauth.wanted_scopes.all? do |scope|
            acceptable_scopes_for(scope, lossy).any? { |s| scopes.include? s }
          end
        end

        def acceptable_scopes_for(scope, lossy = false)
          scopes = case scope = scope.to_s
                   when /^(.+):/      then [$1, scope]
                   when 'public_repo' then [scope, 'repo']
                   else [scope]
                   end

          if lossy
            scopes << 'repo'
            scopes << 'public_repo' if lossy and scope != 'repo'
          end

          scopes
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
          test_target_origin = CGI.unescape(target_origin).downcase
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
