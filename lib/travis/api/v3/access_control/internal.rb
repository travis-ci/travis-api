require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Internal < AccessControl::Generic
    auth_type('internal')

    attr_reader :app, :token, :config

    def self.for_request(type, payload, env)
      new(*payload)
    end

    def initialize(app, token)
      @app = app
      @token = token
      @config = Travis.config.applications[app] || {}
    end

    def full_access?
      logged_in? && config[:full_access]
    end

    def logged_in?
      token == config[:token]
    end

    def admin_for(repository)
      (full_access? && repository.admin) || super
    end
  end
end
