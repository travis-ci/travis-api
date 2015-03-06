require 'gh'


module Travis::API::V3
  class GitHub
    DEFAULT_OPTIONS = {
      client_id:      Travis.config.oauth2.try(:client_id),
      client_secret:  Travis.config.oauth2.try(:client_secret),
      user_agent:     "Travis-API/3 Travis-CI/0.0.1 GH/#{GH::VERSION}",
      origin:         Travis.config.host,
      api_url:        Travis.config.github.api_url,
      ssl:            Travis.config.ssl.merge(Travis.config.github.ssl || {}).to_hash.compact
    }
    private_constant :DEFAULT_OPTIONS

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
        events: [:push, :pull_request, :issue_comment, :public, :member],
        active: flag,
        config: { domain: Travis.config.service_hook_url || '' }
      }

      if hook = gh[hooks_url].detect { |hook| hook['name'.freeze] == 'travis'.freeze }
        gh.patch(hook['_links'.freeze]['self'.freeze]['href'.freeze], payload)
      else
        gh.post(hooks_url, payload)
      end
    end
  end
end