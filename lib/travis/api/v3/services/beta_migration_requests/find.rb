module Travis::API::V3
  class Services::BetaMigrationRequests::Find < Service

    def run!
      user = check_login_and_find(:user)
      not_found(false, :beta_migration_request) if access_control.user != user && !access_control.full_access?

      result query.find(user)
    end
  end
end
