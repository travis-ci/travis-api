require 'travis/api/app'

class Travis::Api::App
  class Middleware
    # Checks access tokens and sets appropriate scopes.
    class ScopeCheck < Middleware
      before do
        next unless token
        access_token = AccessToken.find_by_token(token)
        halt 403, 'access denied' unless access_token
        env['travis.access_token'] = access_token
      end

      after do
        headers['X-OAuth-Scopes'] ||= begin
          scopes = Array(env['travis.access_token'].try(:scopes))
          scopes.map(&:to_s).join(',')
        end
      end

      def token
        @token ||= header_token || query_token || travis_token
      end

      private

        def travis_token
          return unless token = params[:token]
          AccessToken.for_travis_token(token) || ""
        end

        def query_token
          params[:access_token] if params[:access_token] and not params[:access_token].empty?
        end

        def header_token
          type, payload = env['HTTP_AUTHORIZATION'].to_s.split(" ", 2)
          return if payload.nil? or payload.empty?

          case type.downcase
          when 'basic' then payload.unpack("m").first.split(':', 2).first
          when 'token' then payload.gsub(/^"(.+)"$/, '\1')
          end
        end
    end
  end
end
