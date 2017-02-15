module Travis::API::V3
  class Services::Organization::Find < Service
    def run!
      result find
    end
  end
end
