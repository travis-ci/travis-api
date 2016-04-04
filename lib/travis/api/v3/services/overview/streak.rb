module Travis::API::V3
  class Services::Overview::Streak < Service

    def run!
      find(:repository).overview.streak
    end
  end
end
