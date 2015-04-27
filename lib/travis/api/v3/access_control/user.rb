require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::User < AccessControl::Generic
    attr_reader :user, :permissions

    def initialize(user)
      user         = Models::User.find(user.id) if user.is_a? ::User
      @user        = user
      @permissions = user.permissions.where(user_id: user.id)
      super()
    end

    def logged_in?
      true
    end

    def admin_for(repository)
      permission?(:admin, repository) ? user : super
    end

    def visible_repositories(list)
      list.where('repositories.private = false OR repositories.id IN ?'.freeze, permissions.map(&:repository_id))
    end

    protected

    def repository_writable?(repository)
      permission?(:push, repository)
    end

    def private_repository_visible?(repository)
      permission?(:pull, repository)
    end

    def permission?(type, id)
      id = id.id if id.is_a? ::Repository
      permissions.where(type => true, :repository_id => id).any?
    end
  end
end
