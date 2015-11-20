module Travis::API::V3
  class Services::Repositories::ForOwner < Service
    params :active, :private, :starred, prefix: :repository
    paginate(default_limit: 100)

    def run!
      unfiltered = query.for_owner(find(:owner))
      access_control.visible_repositories(unfiltered)
    end
  end
end
