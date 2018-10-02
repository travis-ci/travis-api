require 'travis/api/v3/services/repository/deactivate'

module Travis::API::V3
  class Services::Repository::Activate < Services::Repository::Deactivate
    def run!
      repository = super(true).resource

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
