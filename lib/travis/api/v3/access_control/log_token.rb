require 'travis/api/v3/access_control/generic'
require 'travis/api/v3/log_token'

module Travis::API::V3
  class AccessControl::LogToken < AccessControl::Generic
    auth_type('log.token')

    attr_accessor :token, :repo_can_write

    def self.for_request(type, token, env)
      new(token)
    end

    def initialize(token)
      self.token = token
      self.repo_can_write = Travis::API::V3::LogToken.find(token).repo_can_write
    end

    def temp_access?
      true
    end

    def logged_in?
      false
    end

    def full_access?
      false
    end

    def log_visible?(log)
      token_for_job?(log.job, token)
    end

    private

    def token_for_job?(job, token)
      Travis::API::V3::LogToken.find(token).matches?(job)
    end
  end
end
