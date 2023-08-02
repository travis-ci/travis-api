module Travis::API::V3
  class Services::Repository::Find < Service
    params :server_type

    def run!
      result find
    end
  end
end
