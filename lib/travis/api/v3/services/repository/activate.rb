require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      check_repo_key(repository)
      return repo_migrated if migrated?(repository)

      admin = access_control.admin_for(repository)
      remote_vcs_repository.set_hook(
        repository_id: repository.id,
        user_id: admin.id
      )

      repository.update(active: true)

      if repository.private? || access_control.enterprise?
        remote_vcs_repository.upload_key(
          repository_id: repository.id,
          user_id: admin.id,
          read_only: !Travis::Features.owner_active?(:read_write_github_keys, repository.owner)
        )
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
