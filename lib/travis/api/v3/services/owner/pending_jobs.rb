module Travis::API::V3
  class Services::Owner::PendingJobs < Service
    result_type :jobs

    def run!
      unfiltered   = query(:repositories).for_owner(find(:owner))
      repositories = access_control.visible_repositories(unfiltered)
      query(:jobs).pending(*repositories)
    end
  end
end
