require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Service
    def run!
      repository = check_login_and_find(:repository)
      check_access(repository)
      return repo_migrated if migrated?(repository)

      admin = access_control.admin_for(repository)
      github(admin).set_hook(repository, true)
      repository.update_attributes(active: true)

      if repository.private? || access_control.enterprise?
        github(access_control.admin_for(repository)).upload_key(repository)
      end

      query.sync(access_control.user || access_control.admin_for(repository))
      result repository
    end

    def check_access(repository)
      access_control.permissions(repository).activate!
    end
  end
end
