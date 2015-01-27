require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Application < AccessControl::Generic
    attr_reader :application_name, :config, :user

    def initialize(application_name, user: nil)
      @application_name = application_name
      @config           = Travis.config.applications[application_name]
      @user             = user
      raise ArgumentError, 'unknown application %p'       % application_name unless config
      raise ArgumentError, 'cannot use %p without a user' % application_name if config.requires_user and not user
    end

    def logged_in?
      full_access? or !!user
    end

    protected

    def full_access?
      config.full_access
    end
  end
end
