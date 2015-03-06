module Travis::API::V3
  class Services::Repository::Disable < Service
    def run!(activate = false)
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)

      admin = access_control.admin_for(repository)

      github(admin).set_hook(repository, activate)
      repository.update_attributes(active: activate)

      repository
    end
  end
end
