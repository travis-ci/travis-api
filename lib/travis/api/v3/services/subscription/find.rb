module Travis::API::V3
  class Services::Subscription::Find < Service

    def run!
      result query(:subscription).find
    end
  end
end
