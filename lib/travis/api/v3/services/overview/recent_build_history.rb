module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      find(:repository).overview.recent_build_history
    end
  end
end
