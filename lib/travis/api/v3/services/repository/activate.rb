require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      check_repo_key(repository)
      return repo_migrated if migrated?(repository)

      admin = access_control.admin_for(repository)
      if Travis::Features.user_active?(:use_vcs, admin) || !admin.github?
        remote_vcs_repository.set_hook(
          repository_id: repository.id,
          user_id: admin.id
        )
      else
        github(admin).set_hook(repository, true)
      end
      repository.update_attributes(active: true)

      if repository.private? || access_control.enterprise?
        if Travis::Features.deactivate_owner(:use_vcs, admin) || !admin.github?
          remote_vcs_repository.upload_key(
            repository_id: repository.id,
            user_id: admin.id,
            read_only: !Travis::Features.owner_active?(:read_write_github_keys, repository.owner)
          )
        else
          github(admin).upload_key(repository)
        end
      end

      query.sync(access_control.user || access_control.admin_for(repository))
      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).activate!
    end

    def check_repo_key(repository)
      raise RepoSshKeyMissing if repository.key.nil?
    end
  end
end
