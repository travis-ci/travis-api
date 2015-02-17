module Travis::API::V3
  class Services::Repository::Find < Service
    helpers :repository

    def run!
      repository
    end
  end
end
