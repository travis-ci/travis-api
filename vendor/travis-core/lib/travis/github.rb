require 'gh'
require 'core_ext/hash/compact'
require 'travis/github/education'
require 'travis/github/oauth'
require 'travis/github/services'

module Travis
  module Github
    class << self
      def setup
        GH.set(
          client_id:      Travis.config.oauth2.client_id,
          client_secret:  Travis.config.oauth2.client_secret,
          user_agent:     "Travis-CI/#{Travis::VERSION} GH/#{GH::VERSION}",
          origin:         Travis.config.host,
          api_url:        Travis.config.github.api_url,
          ssl:            Travis.config.ssl.to_h.merge(Travis.config.github.ssl || {}).to_h.compact
        )
      end

      def authenticated(user, &block)
        fail "we don't have a github token for #{user.inspect}" if user.github_oauth_token.blank?
        GH.with(:token => user.github_oauth_token, &block)
      end
    end
  end
end
