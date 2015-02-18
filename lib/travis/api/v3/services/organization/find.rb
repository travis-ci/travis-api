module Travis::API::V3
  class Services::Organization::Find < Service
    helpers :organization

    def run!
      organization
    end
  end
end
