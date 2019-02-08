module Travis::API::V3
  class Services::Preference::ForOrganization < Service
    def run!
      organization = check_login_and_find(:organization)
      result find(:preference, organization)
    end
  end
end
