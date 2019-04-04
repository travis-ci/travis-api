module Travis::API::V3
  class Services::BetaMigrationRequest::Create < Service
    params :organizations
    result_type :beta_migration_request

    def run!
      current_user = check_login_and_find(:user)
      organizations = validate_organizations(current_user)

      beta_migration_request = query(:beta_migration_request).create(current_user, organizations)

      beta_migration_request.save!

      result beta_migration_request
    end

    def validate_organizations(current_user)
      Models::Organization.where(id: params['organizations'], memberships: {user_id: current_user.id, role: "admin"}).joins(:memberships)
    end
  end
end
