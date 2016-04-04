module Travis::API::V3
  class Services::Overview::BuildDuration < Service

    def run!
      find(:repository).build_duration_overview
    end
  end
end
