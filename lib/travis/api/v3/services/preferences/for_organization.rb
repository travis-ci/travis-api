module Travis::API::V3
  class Services::Preferences::ForOrganization < Service
    def run!
      organization = check_login_and_find(:organization)
      prefs = find(:preferences, organization)
      result prefs
    end
  end
end
