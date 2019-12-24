module Travis::API::V3
  class Services::Repositories::ForOwner < Service
    params :active, :private, :starred, :name_filter, :slug_filter,
      :managed_by_installation, :active_on_org, prefix: :repository
    paginate(default_limit: 100)

    def run!
      raise LoginRequired unless access_control.logged_in?
      raise InstallationMissing unless access_control.user.installation
      puts '===================== installation ========================='
      puts access_control.user.installation.to_h
      unfiltered = query.for_owner(find(:owner), user: access_control.user)
      result access_control.visible_repositories(unfiltered)
    end
  end
end
