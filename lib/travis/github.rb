require 'gh'
require 'core_ext/hash/compact'

GH::TokenCheck.class_eval do
  def setup(backend, options)
      puts "called!"
      @client_secret = options[:client_secret]
      @client_id     = options[:client_id]
      @token         = options[:token]
      @check_token   = options[:check_token]
      super
  end
end

module Travis
  module Github
    class << self
      def setup
        GH.set(
          client_id:      Travis.config.oauth2.client_id,
          client_secret:  Travis.config.oauth2.client_secret,
          user_agent:     "GH/#{GH::VERSION}",
          origin:         Travis.config.host,
          api_url:        Travis.config.github.api_url,
          ssl:            Travis.config.ssl.to_h.merge(Travis.config.github.ssl.to_h || {}).to_h.compact,
          check_token:    !is_legacy?
        )
      end

      def authenticated(user, &block)
        fail "we don't have a github token for #{user.inspect}" if user.github_oauth_token.blank?
        GH.with(:token => user.github_oauth_token, &block)
      end

      def is_legacy?
        Travis.config.github.enterprise_legacy_oauth
      end
    end

    require 'travis/github/education'
    require 'travis/github/oauth'
    require 'travis/github/services'
  end
end
