module Travis::API::V3
  class Services::BuildPermissions::FindForOrganization < Service
    def run
      result query.find_for_organization(check_login_and_find(:organization))
    end
  end
end
