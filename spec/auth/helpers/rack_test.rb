require 'auth/helpers/shared'

module Support
  module AuthHelpers
    class RackTest < Struct.new(:ctx)
      include Shared

      extend Forwardable

      def_delegators :ctx, :repo, :user, :request, :build, :job, :log, :last_response
      def_delegators :last_response, :status, :body, :headers

      def set_mode(mode)
        case mode
        when :org
          Travis.config[:host] = 'travis-ci.org'
          Travis.config[:public_mode] = true
        when :public
          Travis.config[:public_mode] = true
        when :private
          Travis.config[:public_mode] = false
        end
      end

      def set_private(value)
        Repository.update_all(private: value)
        Request.update_all(private: value)
        Build.update_all(private: value)
        Job.update_all(private: value)
      end

      def with_permission
        Permission.create!(user_id: ctx.user.id, repository_id: ctx.repo.id, admin: true, push: true)
        token = create_token unless query_token?
        request_with token
      end

      def authenticated
        token = create_token unless query_token?
        request_with token
      end

      def without_permission
        token = create_token unless query_token?
        request_with token
      end

      def invalid_token
        request_with '12345'
      end

      def unauthenticated
        request_with nil
      end

      def create_token
        Travis::Api::App::AccessToken.create(user: ctx.user, app_id: -1).token
      end

      def request_with(token)
        ctx.send(method, path, { access_token: token }, request_headers)
        { status: status, body: body, headers: headers }
      end

      def request_headers
        { 'HTTP_ACCEPT' => accept_header.to_s }
      end
    end
  end
end
