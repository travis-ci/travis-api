module Travis
  module Services
    class AssemblaUserService
      class SyncError < StandardError; end

      def initialize(payload)
        @payload = payload
      end

      def find_or_create_user
        attrs = {
          vcs_id: @payload['id'],
          email: @payload['email'],
          login: @payload['login'],
          vcs_type: 'AssemblaUser'
        }

        user = ::User.find_or_create_by!(attrs)
        user.update(vcs_oauth_token: @payload['refresh_token'])
        sync_user(user.id)
        user
      end

      def find_or_create_organization(user)
        attrs = {
          vcs_id: @payload['space_id'], 
          vcs_type: 'AssemblaOrganization'
        }
        user.organizations.find_or_create_by(attrs)
      end

      def create_org_subscription(user, organization_id)
        client = Travis::API::V3::BillingClient.new(user.id)
        client.create_v2_subscription(subscription_params(user, organization_id))
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
          'plan' => 'beta_plan',
          'organization_id' => organization_id,
          'billing_info' => billing_info(user),
          'credit_card_info' => { 'token' => nil }
        }
      end

      def billing_info(user)
        {
          'address' => "System-generated for user #{user.login} (#{user.id})",
          'city' => "AutoCity-#{user.id}",
          'country' => 'Poland',
          'first_name' => user.name&.split&.first,
          'last_name' => user.name&.split&.last,
          'zip_code' => "000#{user.id}",
          'billing_email' => user.email
        }
      end
    end
  end
end
