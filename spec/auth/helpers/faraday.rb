require 'faraday'
require 'auth/helpers/shared'

# AUTH_TESTS_USER_TOKEN
# AUTH_TESTS_REPO_ID_PRIVATE_WITH_PERMISSION
# AUTH_TESTS_REPO_SLUG_PRIVATE_WITH_PERMISSION
# AUTH_TESTS_REPO_ID_PUBLIC_WITHOUT_PERMISSION
# AUTH_TESTS_REPO_SLUG_PUBLIC_WITHOUT_PERMISSION
# AUTH_TESTS_BUILD_ID_PRIVATE_WITH_PERMISSION
# AUTH_TESTS_BUILD_ID_PRIVATE_WITHOUT_PERMISSION
# AUTH_TESTS_JOB_ID_PRIVATE_WITH_PERMISSION
# AUTH_TESTS_JOB_ID_PRIVATE_WITHOUT_PERMISSION

module Support
  module AuthHelpers
    class Faraday < Struct.new(:ctx)
      class Obj < Struct.new(:attrs)
        def id
          env(:id)
        end

        def slug
          env(:slug)
        end

        def branch
          'master'
        end

        def login
          env(:login)
        end

        def token
          env(:travis_token)
        end

        def env(name)
          ENV.fetch(key(name))
        end

        private

          def key(name)
            key = [:auth_tests]
            key << visibility << scenario unless type == :user
            key << :"#{type}_#{name}"
            key.join('_').upcase
          end

          def visibility
            attrs[:private] ? :private : :public
          end

          def scenario
            attrs[:permission] ? :with_perm : :without_perm
          end

          def type
            attrs[:type]
          end
      end

      include Shared

      %i(user repo request build job log).each do |type|
        define_method type do
          Obj.new(type: type, private: @private, permission: @permission)
        end
      end

      def set_mode(mode)
        ctx.skip if ENV['AUTH_TESTS_MODE'] != mode.to_s
        @host = "http://api-staging.travis-ci.#{mode == :org ? 'org' : 'com'}"
        # set env var on com staging? or
        # check env var on com staging and raise if it does not match?
      end

      def set_private(value)
        @private = value
      end

      def with_permission
        @permission = true
        request_with token
      end

      def authenticated
        request_with token
      end

      def without_permission
        request_with token
      end

      def invalid_token
        request_with '12345'
      end

      def unauthenticated
        request_with nil
      end

      def request_with(token)
        ctx.skip if master? && api_version == :'v2.1'
        ctx.skip if master? && org? && path.include?('?token=')

        WebMock.allow_net_connect!
        resp = client(token).send(method, path)
        WebMock.disable_net_connect!
        { status: resp.status, body: resp.body, headers: resp.headers }
      end

      def client(token)
        ::Faraday.new(url: @host, headers: { accept: accept_header }) do |c|
          # c.response :logger
          c.request  :authorization, :token, token if token
          c.adapter  :net_http
        end
      end

      def master?
        ENV['AUTH_TESTS_BRANCH'] == 'master'
      end

      def org?
        ENV['AUTH_TESTS_TARGET'] == 'org'
      end

      def token
        ENV.fetch('AUTH_TESTS_USER_TOKEN') unless query_token?
      end
    end
  end
end
