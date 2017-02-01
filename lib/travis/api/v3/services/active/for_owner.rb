module Travis::API::V3
  class Services::Active::ForOwner < Service
    def run!
      owner = query(:owner).find
      repositories = access_control.visible_repositories(owner.repositories)
      query(:builds).active_from(repositories)
    end
  end
end
