require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Services::Repository::Deactivate
    def run!
      repository = super(true).resource
      repository = check_login_and_find(:repository)
      check_access(repository)
      check_repo_key(repository)
      return repo_migrated if migrated?(repository)

      admin = access_control.admin_for(repository)
      github(admin).set_hook(repository, true)
      repository.update_attributes(active: true)

      if repository.private? || access_control.enterprise?
        admin = access_control.admin_for(repository)
        github(admin).upload_key(repository)
      end

      query.sync(access_control.user)
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
