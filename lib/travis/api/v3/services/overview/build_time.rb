module Travis::API::V3
  class Services::Overview::BuildTime < Service

    def run!
      find(:repository).build_time
    end
  end
end
