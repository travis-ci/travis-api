module Services
  module Repository
    class Crons
      include Travis::API
      attr_reader :repository

      def initialize(repository)
        @repository = repository
      end

      def access_token
        admin = repository.find_admin
        Travis::AccessToken.create(user: admin, app_id: 2).token if admin
      end

      def call
        extract_body(get("/repo/#{repository.slug}/crons", access_token))
      end

      private

      def extract_body(response)
        response.respond_to?(:body) ? response.body : []
      end
    end
  end
end
