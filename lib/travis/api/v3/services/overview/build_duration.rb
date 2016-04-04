module Travis::API::V3
  class Services::Overview::BuildDuration < Service

    def run!
      find(:repository).overview.build_duration
    end
  end
end
