module Travis::API::V3
  class Services::BetaMigrationRequests::Create < Service
    params :organizations, :user_login
    result_type :beta_migration_request

    def run!
      raise InsufficientAccess unless access_control.full_access?

      current_user = User.find_by!(login: params['user_login'])
      organizations = validate_organizations(current_user, params['organizations'])

      beta_migration_request = query(:beta_migration_request).create(current_user, organizations)

      beta_migration_request.save!

      result beta_migration_request
    end

    def validate_organizations(current_user, organizations)
      Models::Organization.where(
        login: organizations,
        memberships: { user_id: current_user.id, role: 'admin' }
      ).joins(:memberships)
    end
  end
end