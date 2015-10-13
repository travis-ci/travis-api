module Travis::API::V3
  class Services::Owner::Repositories < Service
    params :active, :private, prefix: :repository
    result_type :repositories
    paginate(default_limit: 100)

    def run!
      unfiltered = query(:repositories).for_owner(find(:owner))
      access_control.visible_repositories(unfiltered)
    end
  end
end
