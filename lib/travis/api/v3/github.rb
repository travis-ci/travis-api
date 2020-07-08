require 'gh'
require 'uri'

module Travis::API::V3
  class GitHub
    def self.config
      @config ||= Travis::Config.load
    end

    EVENTS = %i(push pull_request issue_comment public member create delete repository)

    DEFAULT_OPTIONS = {
      client_id:      config.oauth2.try(:client_id),
      client_secret:  config.oauth2.try(:client_secret),
      scopes:         config.oauth2.try(:scope).to_s.split(?,),
      user_agent:     "Travis-API/3 Travis-CI/0.0.1 GH/#{GH::VERSION}",
      origin:         config.host,
      api_url:        config.github.api_url,
      web_url:        config.github.api_url.gsub(%r{\A(https?://)(?:api\.)?([^/]+)(?:/.*)?\Z}, '\1\2'),
      ssl:            config.ssl.to_h.merge(config.github.ssl || {}).compact
    }
    private_constant :DEFAULT_OPTIONS

    HOOKS_URL = "repositories/%i/hooks"
    private_constant :HOOKS_URL

    def self.client_config
      {
        api_url: DEFAULT_OPTIONS[:api_url],
        web_url: DEFAULT_OPTIONS[:web_url],
        scopes:  DEFAULT_OPTIONS[:scopes]
      }
    end

    attr_reader :gh, :user

    def initialize(user = nil, token = nil)
      if user.respond_to? :github_oauth_token
        raise ServerError, 'no GitHub token for user' if user.github_oauth_token.blank?
        token = user.github_oauth_token
      end

      @user = user
      @gh   = GH.with(token: token, **DEFAULT_OPTIONS)
    end

    def set_hook(repo, active)
      set_webhook(repo, active)
      deactivate_service_hook(repo) if Travis.config.enterprise
    end

    def upload_key(repository)
      keys_path = "repositories/#{repository.vcs_id || repository.github_id}/keys"
      key = gh[keys_path].detect { |e| e['key'] == repository.key.encoded_public_key }

      unless key
        gh.post keys_path, {
          title: Travis.config.host.to_s,
          key: repository.key.encoded_public_key,
          read_only: !Travis::Features.owner_active?(:read_write_github_keys, repository.owner)
        }
      end
    end

    def set_webhook(repo, active)
      payload = {
        name: 'web'.freeze,
        events: EVENTS,
        active: active,
        config: { url: service_hook_url.to_s, insecure_ssl: insecure_ssl? }
      }
      if url = webhook_url?(repo)
        info("Updating webhook repo=%s github_id=%i active=%s" % [repo.slug, repo.vcs_id || repo.github_id, active])
        gh.patch(url, payload)
      else
        hooks_url = HOOKS_URL % [repo.vcs_id || repo.github_id]
        info("Creating webhook repo=%s github_id=%i active=%s" % [repo.slug, repo.vcs_id || repo.github_id, active])
        gh.post(hooks_url, payload)
      end
    end

    def deactivate_service_hook(repo)
      if url = service_hook_url?(repo)
        info("Deactivating service hook repo=%s github_id=%i" % [repo.slug, repo.vcs_id || repo.github_id])
        # Have to update events here too, to avoid old hooks failing validation
        gh.patch(url, { events: EVENTS, active: false })
      end
    end

    def service_hook(repo)
      hooks(repo).detect { |h| h['name'] == 'travis' && h.dig('config', 'domain') == service_hook_url.to_s }
    end

    def service_hook_url?(repo)
      if hook = service_hook(repo)
        hook.dig('_links', 'self', 'href')
      end
    end

    def webhook(repo)
      hooks(repo).detect do |h|
        h['name'] == 'web' && URI(h.dig('config', 'url')) == service_hook_url
      end
    end

    def webhook_url?(repo)
      if hook = webhook(repo)
        hook.dig('_links', 'self', 'href')
      end
    end

    def hooks(repo)
      gh[HOOKS_URL % [repo.vcs_id || repo.github_id]]
    end

    def service_hook_url
      url = Travis.config.service_hook_url || ''
      url.prepend('https://') unless url.starts_with?('https://', 'http://')
      URI(url)
    end

    def info(msg)
      Travis.logger.info(msg)
    end

    private

    def insecure_ssl?
      Travis.config.ssl.to_h.key?(:verify) && Travis.config.ssl.to_h[:verify] == false
    end
  end
end
