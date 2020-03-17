require 'travis/api/v3/access_control/generic'

module Travis::API::V3
  class AccessControl::User < AccessControl::Generic
    attr_reader :user, :access_permissions, :token

    def initialize(user)
      user                = Models::User.find(user.id) if user.is_a? ::User
      @user               = user
      @access_permissions = user.permissions.where(user_id: user.id)
      super()
    end

    def logged_in?
      true
    end

    def admin_for(repository)
      permission?(:admin, repository) ? user : super
    end

    def visible_repositories(list, repository_id = nil)
      if repository_id
        if private_access_repository_ids.include?(repository_id)
          list.where('repositories.id = ?', repository_id)
        else
          list.where('repositories.private = false')
        end
      else
        list.where('repositories.private = false OR repositories.id IN (?)'.freeze, private_access_repository_ids)
      end
    end

    protected

    def private_access_repository_ids
      @private_access_repository_ids ||= access_permissions.map(&:repository_id)
    end

    def build_cancelable?(build)
      permission?(:pull, build.repository)
    end

    def build_restartable?(build)
      permission?(:pull, build.repository)
    end

    def job_cancelable?(job)
      permission?(:pull, job.repository)
    end

    def job_restartable?(job)
      permission?(:pull, job.repository)
    end

    def repository_adminable?(repository)
      permission?(:admin, repository)
    end

    def repository_starable?(repository)
      permission?(:pull, repository)
    end

    def organization_visible?(organization)
      super or organization_writable?(organization)
    end

    def organization_writable?(organization)
      organization.members.include? user
    end

    def user_writable?(user)
      user == self.user
    end

    def repository_writable?(repository)
      permission?(:push, repository)
    end

    def private_repository_visible?(repository)
      permission?(:pull, repository)
    end

    def permission?(type, id)
      id = id.id if id.is_a? ::Repository
      access_permissions.where(type => true, :repository_id => id).any?
    end

    private

    def visible_objects(list, repository_id, factory)
      if repository_id
        if private_access_repository_ids.include?(repository_id)
          list.where("#{factory.table_name}.repository_id = ?", repository_id)
        else
          list.where("#{factory.table_name}.private = false")
        end
      else
        list.where("#{factory.table_name}.private = false OR #{factory.table_name}.repository_id IN (?)", private_access_repository_ids)
      end
    end
  end
end
