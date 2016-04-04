module Travis::API::V3
  class Services::Overview::Streak < Service

    def run!
      find(:repository).streak_overview
    end
  end
end
