module Travis::API::V3
  class Services::Owner::Repositories < Service
    result_type :repositories

    def run!
      unfiltered = query(:repositories).for_owner(find)
      access_control.visible_repositories(unfiltered)
    end
  end
end
