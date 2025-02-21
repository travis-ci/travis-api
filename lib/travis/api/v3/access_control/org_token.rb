require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::OrgToken < AccessControl::Generic
    auth_type('org.token')

    attr_accessor :org, :token

    def self.for_request(type, token, env)
      new(token)
    end

    def initialize(token)
      if token.is_a? Array
        self.org = token.first
        self.token = token.last
      elsif token.include?(':')
        self.org = token.split(':')&.first
        self.token = token.split(':')&.last
      else
        self.org = Models::OrganizationToken.find_by(token: self.token)&.organization_id
        self.token = token
      end
    end

    def visible?(object, type = nil)
      return Models::OrganizationToken.where(organization: org).joins(:organization_token_permissions).where(organization_token_permissions: {permission: object})&.first&.token&.split(':')&.last == token
    end

    def logged_in?
      false
    end

    def full_access?
      false
    end
  end
end
