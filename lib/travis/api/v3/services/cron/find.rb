module Travis::API::V3
  class Services::Cron::Find < Service
    #params :id

    def run!
      result find
    end
  end
end
