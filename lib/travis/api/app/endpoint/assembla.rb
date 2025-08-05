require 'travis/api/app'
require 'jwt'
require 'travis/remote_vcs/user'
require 'travis/remote_vcs/repository'
require 'travis/api/v3/billing_client'
require 'travis/services/assembla_user_service'
require_relative '../jwt_utils'

class Travis::Api::App
  class Endpoint
    # Assembla integration endpoint for handling user authentication and organization setup
    class Assembla < Endpoint
      include Travis::Api::App::JWTUtils

      REQUIRED_JWT_FIELDS = %w[name email login space_id repository_id id refresh_token].freeze
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
        access_token = generate_access_token(user: user, app_id: 0)
        puts <<~TEXT
          User_id: #{user.id}
          refresh_token_form_payload: #{@jwt_payload['refresh_token']}
          github_oauth_token: #{user.github_oauth_token}
          repository_id: #{@jwt_payload['repository_id' ]}
          SpaceID: '#{@jwt_payload['space_id']}'
        TEXT

        {
          user_id: user.id,
          login: user.login,
          token: access_token
        }
      end

      private

      def generate_access_token(options)
        AccessToken.create(options).token
      end

      def validate_request!
        halt 403, { error: 'Deep integration not enabled' } unless deep_integration_enabled?
        halt 403, { error: 'Invalid ASM cluster' } unless valid_asm_cluster?
        @jwt_payload = verify_jwt(request)
        check_required_fields
      end

      def check_required_fields
        missing = REQUIRED_JWT_FIELDS.select { |f| @jwt_payload[f].nil? || @jwt_payload[f].to_s.strip.empty? }
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
