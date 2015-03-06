require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::Application < AccessControl::Generic
    attr_reader :application_name, :config, :user, :user_control

    def initialize(application_name, user: nil)
      @application_name = application_name
      @config           = Travis.config.applications[application_name]
      @user             = user
      @user_control     = user ? AccessControl::User.new(user) : AccessControl::Generic.new
      raise ArgumentError, 'unknown application %p'       % application_name unless config
      raise ArgumentError, 'cannot use %p without a user' % application_name if config.requires_user and not user
    end

    def logged_in?
      full_access? or !!user
    end

    def full_access?
      config.full_access
    end

    def admin_for(repository)
      return user_control.admin_for(repository) unless full_access?
      admin = repository.users.where('permissions.admin = true'.freeze).order('users.synced_at DESC'.freeze).first
      raise AdminAccessRequired, "no admin found for #{repository.slug}" unless admin
      admin
    end
  end
end
