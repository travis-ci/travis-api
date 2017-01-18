require 'gh'

module Travis::API::V3
  class GitHub
    DEFAULT_OPTIONS = {
      client_id:      Travis.config.oauth2.try(:client_id),
      client_secret:  Travis.config.oauth2.try(:client_secret),
      scopes:         Travis.config.oauth2.try(:scope).to_s.split(?,),
      user_agent:     "Travis-API/3 Travis-CI/0.0.1 GH/#{GH::VERSION}",
      origin:         Travis.config.host,
      api_url:        Travis.config.github.api_url,
      web_url:        Travis.config.github.api_url.gsub(%r{\A(https?://)(?:api\.)?([^/]+)(?:/.*)?\Z}, '\1\2'),
      ssl:            Travis.config.ssl.merge(Travis.config.github.ssl || {}).to_hash.compact
    }
    private_constant :DEFAULT_OPTIONS

    EVENTS = %i(push pull_request issue_comment public member create delete
      membership repository)
    private_constant :EVENTS

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

    def set_hook(repository, flag)
      hooks_url = "repos/#{repository.slug}/hooks"
      payload   = {
        name:   'travis'.freeze,
        events: EVENTS,
        enabled: flag,
        config: { domain: Travis.config.service_hook_url || '' }
      }

      if hook = gh[hooks_url].detect { |hook| hook['name'.freeze] == 'travis'.freeze }
        gh.patch(hook['_links'.freeze]['self'.freeze]['href'.freeze], payload)
      else
        gh.post(hooks_url, payload)
      end
    end

    def upload_key(repository)
      keys_path = "repos/#{repository.slug}/keys"
      key = gh[keys_path].
        detect { |e| e['key'] == repository.key.encoded_public_key }

      unless key
        gh.post keys_path, title: Travis.config.host.to_s, key: repository.key.encoded_public_key
      end
    end
  end
end
