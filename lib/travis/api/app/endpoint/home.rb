require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Home < Endpoint
      host = Travis.config.client_domain || Travis.config.host
      fail "Travis.config.client_domain is not set" unless host or test?

      set :prefix, '/'
      set :client_config,
        host: host,
        shorten_host: Travis.config.shorten_host,
        assets: Travis.config.assets,
        pusher: (Travis.config.pusher_ws || Travis.config.pusher || {}).to_hash.slice(:scheme, :host, :port, :path, :key, :secure, :private),
        github: { api_url: GH.current.api_host.to_s, scopes: Travis.config.oauth2.try(:scope).to_s.split(?,) }

      # Landing point. Redirects web browsers to [API documentation](#/docs/).
      get '/' do
        pass if settings.disable_root_endpoint?
        redirect to('/docs/') if request.preferred_type('application/json', 'application/json-home', 'text/html') == 'text/html'
        { 'hello' => 'world' }
      end

      # Simple endpoints that redirects somewhere else, to make sure we don't
      # send a referrer.
      #
      # Parameters:
      #
      # * **to**: URI to redirect to after handshake.
      get '/redirect' do
        halt 400 unless params[:to] =~ %r{^https?://}
        redirect params[:to]
      end

      # Provides you with system info:
      #
      #     {
      #       config: {
      #         host: "travis-ci.org",
      #         shorten_host: "trvs.io",
      #         pusher: { key: "dd3f11c013317df48b50" },
      #         assets: {
      #           host: "localhost:3000",
      #           version: "asset-id",
      #           interval: 15
      #         }
      #       }
      #     }
      get '/config' do
        { config: settings.client_config }
      end

      deploy_sha = File.read(".deploy-sha") if File.exist?(".deploy-sha")
      sys_info   = {
        web_concurrency: ENV['WEB_CONCURRENCY'],
        ulimit: `echo "ulimit -u" | bash`.to_i,
        dyno: ENV['DYNO'],
        deploy_sha: deploy_sha
      }

      get '/sysinfo' do
        sys_info
      end
    end
  end
end
