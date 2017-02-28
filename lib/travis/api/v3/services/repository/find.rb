module Travis::API::V3
  class Services::Repository::Find < Service
    def run!
      result find
    end
  end
end
