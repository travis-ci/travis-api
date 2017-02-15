module Travis::API::V3
  class Services::Job::Find < Service
    def run!
      result find
    end
  end
end
