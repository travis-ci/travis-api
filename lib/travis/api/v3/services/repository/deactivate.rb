module Travis::API::V3
  class Services::Repository::Deactivate < Service
    def run!(activate = false)
      repository = check_login_and_find(:repository)
      check_access(repository)

      return repo_migrated if migrated?(repository)

      if access_control.class.name == 'Travis::API::V3::AccessControl::Internal'
        admin = access_control.admin_for(repository)
      else
        admin = access_control.user
      end

      raise InsufficientAccess unless admin&.id

      remote_vcs_repository.set_hook(
        repository_id: repository.id,
        user_id: admin.id,
        activate: activate
      )
      repository.update_attributes(active: activate)
      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).deactivate!
    end
  end
end
