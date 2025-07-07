require 'travis/api/app'
require 'jwt'
require 'travis/remote_vcs/user'
require 'travis/remote_vcs/repository'
require 'travis/api/v3/billing_client'
require_relative '../jwt_utils'

class Travis::Api::App
  class Endpoint
    class Assembla < Endpoint
      include Travis::Api::App::JWTUtils
      set prefix: '/assembla'
      set :check_auth, false

      before do
        halt 403, { error: 'Deep integration not enabled' } unless deep_integration_enabled?
        halt 403, { error: 'Invalid ASM cluster' } unless valid_asm_cluster?
        begin
          @jwt_payload = verify_jwt(request, Travis.config.assembla_jwt_secret)
        rescue JWTUtils::UnauthorizedError => e
          halt 401, { error: e.message }.to_json
        end
      end

      # POST /assembla/login
      # Accepts a JWT, finds or creates a user, and signs them in
      post '/login' do
        user = find_or_create_user(@jwt_payload)
        sync_user(user.id)
        create_org_subscription(user.id, @jwt_payload[:space_id])

        {
          user_id: user.id,
          login: user.login,
          token: user.token,
          status: 'signed_in'
        }.to_json
      end

      private

      def deep_integration_enabled?
        Travis.config.deep_integration_enabled
      end

      def valid_asm_cluster?
        allowed = Array(Travis.config.assembla_clusters.split(','))
        cluster = request.env['HTTP_X_ASSEMBLA_CLUSTER']
        allowed.include?(cluster)
      end

      # Finds or creates a user based on the payload
      def find_or_create_user(payload)
        required_fields = %w[name email login space_id]
        missing = required_fields.select { |f| payload[f].nil? || payload[f].to_s.strip.empty? }
        unless missing.empty?
          halt 400, { error: 'Missing required fields', missing: missing }.to_json
        end
        attrs = {
          name: payload['name'],
          email: payload['email'],
          login: payload['login'],
          org_id: payload['space_id'],
          vcs_type: 'AssemblaUser'
        }
        ::User.find_or_create_by!(attrs)
      end

      def sync_user(user_id)
        Travis::RemoteVCS::User.new.sync(user_id: user_id)
      rescue => e
        halt 500, { error: 'User sync failed', details: e.message }.to_json
      end

      def create_org_subscription(user_id, space_id)
        plan = 'beta_plan'
        client = Travis::API::V3::BillingClient.new(user_id)
        client.create_v2_subscription({
          'plan' => plan,
          'organization_id' => space_id,
        })
      rescue => e
        halt 500, { error: 'Subscription creation failed', details: e.message }.to_json
      end
    end
  end
end