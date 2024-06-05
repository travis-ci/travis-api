module Travis::API::V3
  class Services::Repositories::ForOwner < Service
    params :active, :private, :starred, :name_filter, :slug_filter,
      :managed_by_installation, :active_on_org, prefix: :repository
    paginate(default_limit: 100)
    def run!
      result = nil
      time = Benchmark.measure do
        unfiltered = query.for_owner(find(:owner), user: access_control.user)
        result = access_control.visible_repositories(unfiltered)
      end
      puts "Time for for_owner run!: #{time}"
      result
    end
  end
end
