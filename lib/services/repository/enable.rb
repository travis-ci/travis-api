require 'travis/api'

module Services
  module Repository
    class Enable
      include Travis::API
      attr_reader :repository_id

      def initialize(repository_id)
        @repository_id = repository_id
      end

      def access_token
        ENV['TRAVIS_API_TOKEN']
      end

      def call
        url = "/repo/#{repository_id}/enable"
        post(url, access_token)
      end
    end
  end
end
