module Services
  module Repository
    class Crons
      include Travis::API

      def initialize(repository)
        @repository = repository
      end

      def call
        extract_body(get("/repo/#{repository.url_slug}/crons", access_token))
      end

      private

      attr_reader :repository

      def access_token
        admin = repository.find_admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def extract_body(response)
        body = JSON.parse(response.body)
        body['crons']
      rescue
        []
      end
    end
  end
end
