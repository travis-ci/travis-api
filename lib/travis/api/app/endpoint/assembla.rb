require 'travis/api/app'
require 'jwt'
require 'travis/remote_vcs/user'
require 'travis/remote_vcs/repository'

class Travis::Api::App
  class Endpoint
    class Assembla < Endpoint
      set prefix: '/assembla'
      set :check_auth, false

      before do
        halt 403, { error: 'Deep integration not enabled' } unless deep_integration_enabled?
        halt 403, { error: 'Invalid ASM cluster' } unless valid_asm_cluster?
        @jwt_payload = verify_jwt
      end

      # POST /assembla/login
      # Accepts a JWT, finds or creates a user, and signs them in
      post '/login' do
        user = find_or_create_user(@jwt_payload)
        begin
          Travis::RemoteVCS::User.new.sync(user_id: user.id)
        rescue => e
          halt 500, { error: 'User sync failed', details: e.message }.to_json
        end
        { user_id: user.id, login: user.login, token: user.token, status: 'signed_in' }.to_json
      end

      private

      def verify_jwt
        token = extract_jwt_token
        halt 401, { error: 'Missing JWT' } unless token
        secret = Travis.config.assembla_jwt_secret
        begin
          decoded, = JWT.decode(token, secret, true, { algorithm: 'HS256' })
          decoded
        rescue JWT::DecodeError => e
          halt 401, { error: 'Invalid JWT', details: e.message }
        end
      end

      def extract_jwt_token
        request.env['HTTP_AUTHORIZATION']&.split(' ')&.last
      end

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
        ::User.first_or_create!(attrs)
      end
    end
  end
end