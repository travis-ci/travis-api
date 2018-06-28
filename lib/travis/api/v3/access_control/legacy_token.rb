require 'travis/api/app/access_token'
require 'travis/api/v3/access_control/user'

module Travis::API::V3
  # Using v2 API tokens to access v3 API.
  # Allows us to later introduce a new way of storing tokens with more capabilities without API users having to know.
  class AccessControl::LegacyToken < AccessControl::User
    auth_type('token', 'basic')

    def self.for_request(type, payload, env)
      payload = payload.first if payload.is_a? Array
      token   = Travis::Api::App::AccessToken.find_by_token(payload)
      new(token) if token
    end

    def initialize(token)
      @token = token
      super(token.user)
    end

    protected

    def permission?(action, id)
      super if @token.scopes.include? :private
    end
  end
end
