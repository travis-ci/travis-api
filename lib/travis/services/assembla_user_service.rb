module Travis
  module Services
    class AssemblaUserService
      class SyncError < StandardError; end

      def initialize(payload)
        @payload = payload
      end

      def find_or_create_user
        user = ::User.find_or_initialize_by(
          name: @payload['name'],
          vcs_id: @payload['id'],
          email: @payload['email'],
          login: @payload['login'],
          vcs_type: 'AssemblaUser'
        )
        user.vcs_oauth_token = @payload['refresh_token']
        user.save!
        sync_user(user.id)
        user
      end

      def find_or_create_organization(user)
        user.organizations.find_or_create_by!(
          vcs_id: @payload['space_id'], 
          vcs_type: 'AssemblaOrganization'
        )
      end

      def create_org_subscription(user, organization_id)
        billing_client = Travis::API::V3::BillingClient.new(user.id)
        billing_client.create_v2_subscription(subscription_params(user, organization_id))
      rescue => e
        { error: true, details: e.message }
      end

      private

      def sync_user(user_id)
        Travis::RemoteVCS::User.new.sync(user_id: user_id)
      rescue => e
        raise SyncError, "Failed to sync user: #{e.message}"
      end

      def subscription_params(user, organization_id)
        {
          'plan' => Travis.config.deep_integration_plan_name,
          'organization_id' => organization_id,
          'billing_info' => billing_info(user),
          'credit_card_info' => { 'token' => nil }
        }
      end

      def billing_info(user)
        {
          'address' => 'Dummy Address',
          'city' => 'Dummy City',
          'country' => 'Dummy Country',
          'first_name' => user.name&.split&.first,
          'last_name' => user.name&.split&.last,
          'zip_code' => 'DUMMY ZIP',
          'billing_email' => user.email
        }
      end
    end
  end
end
