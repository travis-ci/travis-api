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
      set prefix: '/auth'

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

        { 'access_token' => github_to_travis(params[:github_token], app_id: 1, drop_token: true) }
      end

      # Endpoint for making sure user authorized Travis CI to access GitHub.
      # There are no restrictions on where to redirect to after handshake.
      # However, no information whatsoever is being sent with the redirect.
      #
      # Parameters:
      #
      # * **redirect_uri**: URI to redirect to after handshake.
      get '/handshake' do
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
      #       console.log("received token: " + event.data.token);
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
        content_type :html
        erb :container
      end

      get '/post_message/iframe', scope: :public do
        handshake do |user, token, target_origin|
          halt 403, invalid_target(target_origin) unless target_ok? target_origin
          post_message(token: token, user: user, target_origin: target_origin)
        end
      end

      error Faraday::Error::ClientError do
        halt 401, 'could not resolve github token'
      end

      private

        def serialize_user(user)
          rendered = Travis::Api.data(user, version: :v2)
          rendered['user'].merge('token' => user.tokens.first.try(:token).to_s)
        end

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
            yield serialize_user(user), token, payload
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
            info['github_id'] ||= data['id']
            info
          end

          def user_exists?
            user
          end

          def fetch
            retried ||= false
            info   = drop_token ? self.info : self.info(github_oauth_token: token)

            ActiveRecord::Base.transaction do
              if user
                rename_repos_owner(user.login, info['login'])
                user.update_attributes info
              else
                self.user = ::User.create! info
              end

              nullify_logins(user.github_id, user.login)
            end

            user
          rescue ActiveRecord::RecordNotUnique
            unless retried
              retried = true
              retry
            end
          end
        end

        def user_for_github_token(token, drop_token = false)
          data    = GH.with(token: token.to_s, client_id: nil) { GH['user'] }
          scopes  = parse_scopes data.headers['x-oauth-scopes']
          manager = UserManager.new(data, token, drop_token)

          unless acceptable? scopes
            # TODO: we should probably only redirect if this is a web
            #      oauth request, are there any other possibilities to
            #      consider?
            url =  Travis.config.oauth2.insufficient_access_redirect_url
            url += "#existing-user" if manager.user_exists?
            redirect to(url)
          end

          user   = manager.fetch
          halt 403, 'not a Travis user' if user.nil?
          user
        end

        def get_token(endoint, values)
          response   = Faraday.post(endoint, values)
          parameters = Addressable::URI.form_unencode(response.body)
          token_info = parameters.assoc("access_token")
          halt 401, 'could not resolve github token' unless token_info
          token_info.last
        end

        def parse_scopes(data)
          data.gsub(/\s/,'').split(',') if data
        end

        def generate_token(options)
          AccessToken.create(options).token
        end

        def acceptable?(scopes)
          User::Oauth.wanted_scopes.all? do |scope|
            acceptable_scopes_for(scope).any? { |s| scopes.include? s }
          end
        end

        def acceptable_scopes_for(scope)
          case scope = scope.to_s
          when /^user/       then ['user', scope, 'public_repo', 'repo']
          when /^(.+):/      then [$1, scope]
          when 'public_repo' then [scope, 'repo']
          else [scope]
          end
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
          if uri.host =~ /\A(.+\.)?travis-ci\.(com|org)\Z/
            uri.scheme == 'https'
          elsif uri.host =~ /\A(.+\.)?travis-lite\.com\Z/
            uri.scheme == 'https'
          elsif uri.host == 'localhost' or uri.host == '127.0.0.1'
            uri.port > 1023
          end
        end
    end
  end
end

__END__

@@ invalid_target
<script>
console.log('refusing to send a token to <%= target_origin.inspect %>, not whitelisted!');
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
  doYouHave(thirdPartyCookies,
    yesIndeed("third party cookies enabled, creating iframe",
      doYouHave(iframe(after(5)),
        yesIndeed("iframe succeeded", done),
        nopeSorry("iframe taking too long, creating pop-up",
          doYouHave(popup(after(5)),
            yesIndeed("pop-up succeeded", done),
            nopeSorry("pop-up failed, redirecting", redirect))))),
    nopeSorry("third party cookies disabled, creating pop-up",
      doYouHave(popup(after(8)),
        yesIndeed("popup succeeded", done),
        nopeSorry("popup failed", redirect))))();
}

// === THE LOGIC ===
var url = window.location.pathname + '/iframe' + window.location.search;

function thirdPartyCookies(yes, no) {
  window.cookiesCheckCallback = function(enabled) { enabled ? yes() : no() };
  var img      = document.createElement('img');
  img.src      = "https://third-party-cookies.herokuapp.com/set";
  img.onload   = function() {
    var script = document.createElement('script');
    script.src = "https://third-party-cookies.herokuapp.com/check";
    window.document.body.appendChild(script);
  }
}

function iframe(time) {
  return function(yes, no) {
    var iframe = document.createElement('iframe');
    iframe.src = url;
    timeout(time, yes, no);
    window.document.body.appendChild(iframe);
  }
}

function popup(time) {
  return function(yes, no) {
    if(popupWindow) {
      timeout(time, yes, function() {
        if(popupWindow.closed || popupWindow.innerHeight < 1) {
          no()
        } else {
          try {
            popupWindow.focus();
            popupWindow.resizeTo(900, 500);
          } catch(err) {
            no()
          }
        }
      });
    } else {
      no()
    }
  }
}

function done() {
  if(popupWindow && !popupWindow.closed) popupWindow.close();
}

function redirect() {
  tellEveryone('redirect');
}

function createPopup() {
  if(!popupWindow) popupWindow = window.open(url, 'Signing in...', 'height=50,width=50');
}

// === THE PLUMBING ===
<%= erb :common %>

function timeout(time, yes, no) {
  var timeout = setTimeout(no, time);
  onSuccess(function() {
    clearTimeout(timeout);
    yes()
  });
}

function onSuccess(callback) {
  succeeded ? callback() : callbacks.push(callback)
}

function doYouHave(feature, yes, no) {
  return function() { feature(yes, no) };
}

function yesIndeed(msg, callback) {
  return function() {
    if(console && console.log) console.log(msg);
    return callback();
  }
}

function after(value) {
  return value*1000;
}

var nopeSorry = yesIndeed;
var timeoutes = [];
var callbacks = [];
var seconds   = 1000;
var succeeded = false;
var popupWindow;

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
