module Travis::API::V3
  class Services::Repository::Enable < Services::Repository::Disable
    def run!
      repository = super(true)

      if repository.private?
        admin = access_control.admin_for(repository)
        github(admin).upload_key(repository)
      end

      query.sync(access_control.user)
      repository
    end

    def check_access(repository)
      access_control.permissions(repository).enable!
    end
  end
end
