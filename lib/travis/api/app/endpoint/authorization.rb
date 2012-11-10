require 'travis/api/app'
require 'addressable/uri'
require 'faraday'
require 'securerandom'

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
    # The entry point is [/auth/github](#/auth/github).
    #
    # ## Cross-Origin Window Messages
    #
    # This is the recommended way for the official client. We might improve the
    # authorization flow to support third-party clients in the future, too.
    #
    # The entry point is [/auth/post_message](#/auth/post_message).
    class Authorization < Endpoint
      enable :inline_templates
      set prefix: '/auth', allowed_targets: %r{
        ^ http://   (localhost|127\.0\.0\.1)(:\d+)?  $ |
        ^ https://  ([\w\-_]+\.)?travis-ci\.(org|com) $
      }x

      # Endpoint for retrieving an authorization code, which in turn can be used
      # to generate an access token.
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
      # * **token**: GitHub token for checking authorization (required)
      post '/github' do
        { 'access_token' => github_to_travis(params[:token], app_id: 1) }
      end

      # Endpoint for making sure user authorized Travis CI to access GitHub.
      # There are no restrictions on where to redirect to after handshake.
      # However, no information whatsoever is being sent with the redirect.
      #
      # Parameters:
      #
      # * **redirect_uri**: URI to redirect to after handshake.
      get '/handshake' do
        handshake do |*, redirect_uri|
          safe_redirect redirect_uri
        end
      end

      # This endpoint is meant to be embedded in an iframe, popup window or
      # similar. It will perform the handshake and, once done, will send an
      # access token and user payload to the parent window via postMessage.
      #
      # However, the endpoint to send the payload to has to be explicitely
      # whitelisted in production, as this is endpoint is only meant to be used
      # with the official Travis CI client at the moment.
      #
      # Example usage:
      #
      #     window.addEventListener("message", function(event) {
      #       alert("received token: " + event.data.token);
      #     });
      #
      #     var iframe = $('<iframe />').hide();
      #     iframe.appendTo('body');
      #     iframe.attr('src', "https://api.travis-ci.org/auth/post_message");
      #
      # Note that embedding it in an iframe will only work for users that are
      # logged in at GitHub and already authorized Travis CI. It is therefore
      # recommended to redirect to [/auth/handshake](#/auth/handshake) if no
      # token is being received.
      get '/post_message', scope: :public do
        handshake do |user, token, target_origin|
          halt 403, invalid_target(target_origin) unless target_ok? target_origin
          rendered_user = Travis::Api.data(user, version: :v2)
          travis_token  = user.tokens.first
          post_message(token: token, user: rendered_user, target_origin: target_origin,
                       travis_token: travis_token ? travis_token.token : nil)
        end
      end

      error Faraday::Error::ClientError do
        halt 401, 'could not resolve github token'
      end

      private

        def oauth_endpoint
          proxy = Travis.config.oauth2.proxy
          proxy ? File.join(proxy, request.fullpath) : url
        end

        def handshake
          config   = Travis.config.oauth2
          endpoint = Addressable::URI.parse(config.authorization_server)
          values   = {
            client_id:    config.client_id,
            scope:        config.scope,
            redirect_uri: oauth_endpoint
          }

          if params[:code] and state_ok?(params[:state])
            endpoint.path          = config.access_token_path
            values[:state]         = params[:state]
            values[:code]          = params[:code]
            values[:client_secret] = config.client_secret
            github_token           = get_token(endpoint.to_s, values)
            user                   = user_for_github_token(github_token)
            token                  = generate_token(user: user, app_id: 0)
            payload                = params[:state].split(":::", 2)[1]
            yield user, token, payload
          else
            values[:state]         = create_state
            endpoint.path          = config.authorize_path
            endpoint.query_values  = values
            redirect to(endpoint.to_s)
          end
        end

        def create_state
          state = SecureRandom.urlsafe_base64(16)
          redis.sadd('github:states', state)
          redis.expire('github:states', 1800)
          payload = params[:origin] || params[:redirect_uri]
          state << ":::" << payload if payload
          state
        end

        def state_ok?(state)
          redis.srem('github:states', state.split(":::", 1)) if state
        end

        def github_to_travis(token, options = {})
          generate_token options.merge(user: user_for_github_token(token))
        end

        def user_info(data, misc = {})
          info = data.to_hash.slice('name', 'login', 'github_oauth_token', 'gravatar_id')
          info.merge! misc
          info['github_id'] ||= data['id']
          info
        end

        def user_for_github_token(token)
          data   = GH.with(token: token.to_s) { GH['user'] }
          scopes = parse_scopes data.headers['x-oauth-scopes']
          user   = ::User.find_by_github_id(data['id'])
          user ||= ::User.create! user_info(data, github_oauth_token: token)

          halt 403, 'not a Travis user'   if user.nil?
          halt 403, 'insufficient access' unless acceptable? scopes
          user
        end

        def get_token(endoint, values)
          response   = Faraday.post(endoint, values)
          parameters = Addressable::URI.form_unencode(response.body)
          parameters.assoc("access_token").last
        end

        def parse_scopes(data)
          data.gsub(/\s/,'').split(',') if data
        end

        def generate_token(options)
          AccessToken.create(options).token
        end

        def acceptable?(scopes)
          scopes.include? 'public_repo' or scopes.include? 'repo'
        end

        def post_message(payload)
          content_type :html
          p [:payload, payload]
          erb(:post_message, locals: payload)
        end

        def invalid_target(target_origin)
          content_type :html
          erb(:invalid_target, {}, target_origin: target_origin)
        end

        def target_ok?(target_origin)
          target_origin =~ settings.allowed_targets
        end
    end
  end
end

__END__

@@ invalid_target
<script>
alert('refusing to send a token to <%= target_origin.inspect %>, not whitelisted!');
</script>

@@ post_message
<script>
var payload = <%= user.to_json %>;
payload.token = <%= token.inspect %>;
payload.travis_token = <%= travis_token ? travis_token.inspect : null %>;
window.parent.postMessage(payload, <%= target_origin.inspect %>);
</script>
