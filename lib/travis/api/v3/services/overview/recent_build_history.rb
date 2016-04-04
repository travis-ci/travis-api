module Travis::API::V3
  class Services::Overview::RecentBuildHistory < Service

    def run!
      model = Models::Overview.new(find(:repository))
      model.recent_build_history
    end
  end
end
