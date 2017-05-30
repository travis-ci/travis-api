module Travis::API::V3
  class Services::Build::Find < Service
    def run!
      result find
    end
  end
end
