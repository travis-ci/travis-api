module Travis::API::V3
  class Services::Repository::Deactivate < Service
    def run!(activate = false)
      repository = check_login_and_find(:repository)
      check_access(repository)
      return repo_migrated if migrated?(repository)

      admin = access_control.admin_for(repository)

      if Travis::Features.user_active?(:use_vcs, admin) || !admin.github?
        remote_vcs_repository.set_hook(
          repository_id: repository.id,
          user_id: admin.id,
          activate: activate
        )
      else
        github(admin).set_hook(repository, activate)
      end
      repository.update_attributes(active: activate)

      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).deactivate!
    end
  end
end
