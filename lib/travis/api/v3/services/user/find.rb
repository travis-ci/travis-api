module Travis::API::V3
  class Services::User::Find < Service
    def run!
      result find
    end
  end
end
