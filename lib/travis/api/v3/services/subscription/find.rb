module Travis::API::V3
  class Services::Subscription::Find < Service

    def run!
      result find
    end
  end
end
