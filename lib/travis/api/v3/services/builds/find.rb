module Travis::API::V3
  class Services::Builds::Find < Service
    def run!
      find(:builds, find(:repository))
    end
  end
end
