module Travis::API::V3
  class Services::Installation::Find < Service
    def run!
      result find
    end
  end
end
