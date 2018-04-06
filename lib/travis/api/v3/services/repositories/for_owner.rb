module Travis::API::V3
  class Services::Repositories::ForOwner < Service
    params :active, :private, :starred, :slug_filter, :managed_by_installation, prefix: :repository
    paginate(default_limit: 100)

    def run!
      unfiltered = query.for_owner(find(:owner), user: access_control.user)
      result access_control.visible_repositories(unfiltered)
    end
  end
end
