require 'travis/api/app'
require 'jwt'
require 'travis/remote_vcs/user'
require 'travis/remote_vcs/repository'
require 'travis/api/v3/billing_client'
require 'travis/services/assembla_user_service'
require 'travis/services/assembla_notify_service'
require 'travis/remote_vcs/client'
require 'pry'
require_relative '../jwt_utils'


class Travis::Api::App
  class Endpoint
    # Assembla integration endpoint for handling user authentication and organization setup
    class Assembla < Endpoint
      include Travis::Api::App::JWTUtils

      REQUIRED_JWT_FIELDS = %w[name email login space_id repository_id id refresh_token].freeze
      REQUIRED_NOTIFY_FIELDS = %w[action object id].freeze
      CLUSTER_HEADER = 'HTTP_X_ASSEMBLA_CLUSTER'.freeze

      set prefix: '/assembla'
      set :check_auth, false

      before do
        validate_request!
      end

      post '/login' do
        service = Travis::Services::AssemblaUserService.new(@jwt_payload)
        
        user = service.find_or_create_user
        org = service.find_or_create_organization(user)
        service.create_org_subscription(user, org.id)
        access_token = AccessToken.create(user: user, app_id: 0).token

        {
          user_id: user.id,
          login: user.login,
          token: access_token,
          asset_token: user.asset_token,
          rss_token: user.rss_token
        }
      end

      post '/notify' do
        @jwt_payload = {object: 'space', action: 'destroy', id: 120}
        service = Travis::Services::AssemblaNotifyService.new(@jwt_payload)
        if service.run
          {
            status: 200,
            body: { message: 'Assembla notification processed successfully' }
          }
        else
          Travis.logger.error("Failed to process Assembla notification")
          halt 500, { error: 'Failed to process notification' }
        end
      end

      private

      def validate_request!
        halt 403, { error: 'Deep integration not enabled' } unless deep_integration_enabled?
        halt 403, { error: 'Invalid ASM cluster' } unless valid_asm_cluster?
        @jwt_payload = verify_jwt(request)
        check_required_fields
      end

      def check_required_fields
        required_fields = if request.path_info.end_with?('/notify')
                           REQUIRED_NOTIFY_FIELDS
                         else
                           REQUIRED_JWT_FIELDS
                         end
        missing = required_fields.select { |f| @jwt_payload[f].nil? || @jwt_payload[f].to_s.strip.empty? }
        unless missing.empty?
          halt 400, { error: 'Missing required fields', missing: missing }
        end
      end

      def deep_integration_enabled?
        Travis.config.deep_integration_enabled
      end

      def valid_asm_cluster?
        allowed = Travis.config.assembla_clusters
        allowed.include?(request.env[CLUSTER_HEADER])
      end
    end
  end
end
