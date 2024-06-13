require 'gh'
require 'core_ext/hash/compact'

GH::Remote.class_eval do
  def http(verb, url, headers = {}, &block)
    body = headers.delete :body
    connection.run_request(verb, url, body, headers, &block)
  rescue Exception => error
    raise Error.new(error, nil, :verb => verb, :url => url, :headers => headers)
  end
end

GH::TokenCheck.class_eval do

    def check_token
      return unless @check_token and client_id and client_secret and token
      @check_token = false
      auth_header = "Basic %s" % Base64.encode64("#{client_id}:#{client_secret}").gsub("\n", "")

      if is_legacy?
        http :head, path_for("/applications/#{client_id}/tokens/#{token}?client_id=#{client_id}&client_secret=#{client_secret}"), "Authorization" => auth_header
      else
        http :post, path_for("/applications/#{client_id}/token"), :body => "{\"access_token\": \"#{token}\"}", "Authorization" => auth_header
      end
    rescue GH::Error(:response_status => 404) => error
      raise GH::TokenInvalid, error
    end

    def is_legacy?
      Travis.config.github.enterprise_legacy_oauth
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
          ssl:            Travis.config.ssl.to_h.merge(Travis.config.github.ssl.to_h || {}).to_h.compact
        )
      end

      def authenticated(user, &block)
        fail "we don't have a github token for #{user.inspect}" if user.github_oauth_token.blank?
        GH.with(:token => user.github_oauth_token, &block)
      end
    end

    require 'travis/github/education'
    require 'travis/github/oauth'
    require 'travis/github/services'
  end
end
