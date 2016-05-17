module Travis::API::V3
  class Services::Overview::History < Service

    def run!
      find(:repository).history
    end
  end
end
