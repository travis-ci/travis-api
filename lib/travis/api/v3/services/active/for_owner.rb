module Travis::API::V3
  class Services::Active::ForOwner < Service
    def run!
      owner = query(:owner).find
      query(:builds).active_for(owner)
    end
  end
end
