module Travis::API::V3
  class Services::Repositories::ForCurrentUser < Service
    params :active, :private, :starred, :name_filter, :slug_filter,
      :managed_by_installation, :active_on_org, prefix: :repository
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      raise InstallationMissing unless access_control.user.installation
      puts '===================== installation ========================='
      puts access_control.user.installation.to_h
      result query.for_member(access_control.user)
    end
  end
end
