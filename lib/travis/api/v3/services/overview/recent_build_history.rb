module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      find(:repository).recent_build_history_overview
    end
  end
end
