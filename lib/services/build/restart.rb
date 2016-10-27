require 'travis/api'

module Services
  module Build
    class Restart
      include Travis::API
      attr_reader :build

      def initialize(build)
        @build = build
      end

      def access_token
        admin = build.repository.find_admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def call
        url = "/build/#{build.id}/restart"
        post(url, access_token)
      end
    end
  end
end
