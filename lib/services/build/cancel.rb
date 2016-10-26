require 'travis/api'

module Services
  module Build
    class Cancel
      include Travis::API
      attr_reader :build_id

      def initialize(build_id)
        @build_id = build_id
      end

      def access_token
        ENV['TRAVIS_API_TOKEN']
      end

      def call
        url = "/build/#{build_id}/cancel"
        post(url, access_token)
      end
    end
  end
end
