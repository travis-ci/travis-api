module Travis::API::V3
  class Services::Request::Find < Service

    def run!
      result find
    end
  end
end
