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
    # ## Cross-Origin Window Messages
    #
    # This is the recommended way for the official client. We might improve the
    # authorization flow to support third-party clients in the future, too.
    class Authorization < Endpoint
      set prefix: '/auth'
      enable :inline_templates

      configure :development, :test do
        set :target_origins, ['*']
      end

      configure :production do
        set :target_origins, %W[
          https://#{Travis.config.domain}
          https://staging.#{Travis.config.domain}
          https://travis-ember.herokuapp.com
        ]
      end

      # Parameters:
      #
      # * **client_id**: your App's client id (required)
      # * **redirect_uri**: URL to redirect to
      # * **scope**: requested access scope
      # * **state**: should be random string to prevent CSRF attacks
      get '/authorize' do
        raise NotImplementedError
      end

      # Parameters:
      #
      # * **client_id**: your App's client id (required)
      # * **client_secret**: your App's client secret (required)
      # * **code**: code retrieved from redirect from [/authorize](#/authorize) (required)
      # * **redirect_uri**: URL to redirect to
      # * **state**: same value sent to [/authorize](#/authorize)
      post '/access_token' do
        raise NotImplementedError
      end

      # Parameters:
      #
      # * **token**: GitHub token for checking authorization (required)
      post '/github' do
        { 'access_token' => github_to_travis(params[:token], app_id: 1) }
      end

      get '/post_message' do
        config   = Travis.config.oauth2
        endpoint = Addressable::URI.parse(config.authorization_server)
        values   = {
          client_id:    config.client_id,
          scope:        config.scope,
          redirect_uri: url
        }

        if params[:code] and state_ok?(params[:state])
          endpoint.path          = config.access_token_path
          values[:state]         = params[:state]
          values[:code]          = params[:code]
          values[:client_secret] = config.client_secret
          github_token           = get_token(endpoint.to_s, values)
          user                   = user_for_github_token(github_token)
          token                  = generate_token(user: user, app_id: 0)
          rendered_user          = service(:user, user).find_one
          post_message(token: token, user: rendered_user)
        else
          values[:state]         = create_state
          endpoint.path          = config.authorize_path
          endpoint.query_values  = values
          redirect to(endpoint.to_s)
        end
      end

      error Faraday::Error::ClientError do
        halt 401, 'could not resolve github token'
      end

      private

        def create_state
          state = SecureRandom.urlsafe_base64(16)
          redis.sadd('github:states', state)
          redis.expire('github:states', 1800)
          state
        end

        def state_ok?(state)
          redis.srem('github:states', state) if state
        end

        def github_to_travis(token, options = {})
          generate_token options.merge(user: user_for_github_token(token))
        end

        def user_for_github_token(token)
          data   = GH.with(token: token.to_s) { GH['user'] }
          scopes = parse_scopes data.headers['x-oauth-scopes']
          user   = User.find_by_login(data['login'])

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
          erb(:post_message, locals: payload)
        end
    end
  end
end

__END__

@@ post_message
<script>
var payload = <%= render_json(user) %>;
payload.token = <%= token.inspect %>;
<% settings.target_origins.each do |target| %>
  window.parent.postMessage(payload, <%= target.inspect %>);
<% end %>
</script>
