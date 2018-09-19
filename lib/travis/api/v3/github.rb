require 'gh'

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

    HOOKS_URL = "repos/%s/hooks"
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
      deactivate_service_hook(repo)
    end

    def upload_key(repository)
      keys_path = "repos/#{repository.slug}/keys"
      key = gh[keys_path].detect { |e| e['key'] == repository.key.encoded_public_key }

      unless key
        gh.post keys_path, {
          title: Travis.config.host.to_s,
          key: repository.key.encoded_public_key,
          read_only: !Travis::Features.owner_active?(:read_write_github_keys, repository.owner)
        }
      end
    end

    private

    def set_webhook(repo, active)
      payload = {
        name: 'web'.freeze,
        events: EVENTS,
        active: active,
        config: { url: Travis.config.service_hook_url || '' }
      }
      if url = webhook_url?(repo)
        gh.patch(url, payload)
      else
        hooks_url = HOOKS_URL % [repo.slug]
        gh.post(hooks_url, payload)
      end
    end

    def deactivate_service_hook(repo)
      if url = service_hook_url?(repo)
        gh.patch(url, { active: false })
      end
    end

    def service_hook_url?(repo)
      hook_url?(repo, 'travis')
    end

    def webhook_url?(repo)
      hook_url?(repo, 'web')
    end

    def hook_url?(repo, type)
      hooks_url = HOOKS_URL % [repo.slug]
      if hook = gh[hooks_url].detect { |hook| hook['name'.freeze] == type }
        hook['_links'.freeze]['self'.freeze]['href'.freeze]
      end
    end
  end
end
