module Travis::API::V3
  class Services::BetaMigrationRequests::Create < Service
    params :organizations, :user_login
    result_type :beta_migration_request

    def run!
      raise InsufficientAccess unless access_control.full_access?

      current_user = User.find_by!(login: params['user_login'])
      organizations = validate_organizations(current_user, params['organizations'])

      beta_migration_request = query(:beta_migration_request).create(current_user, organizations)

      # This now automatically accepts the request
      beta_migration_request.save!

      enable_migration_feature_flags(current_user, organizations)
      send_acceptance_notification(current_user)

      result beta_migration_request
    end

    def validate_organizations(current_user, organizations)
      Models::Organization.where(
        login: organizations,
        memberships: { user_id: current_user.id, role: 'admin' }
      ).joins(:memberships)
    end

    private

    def enable_migration_feature_flags(current_user, organizations)
      (organizations + [current_user]).each do |owner|
        Travis::Features.activate_owner(:allow_migration, owner)
      end
    end

    def send_acceptance_notification(user)
      @mailer ||= Travis::API::V3::Models::Mailer.new
      @mailer.send_beta_confirmation(user)
    end
  end
end
