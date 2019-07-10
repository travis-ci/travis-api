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
        get("/repo/#{repository.slug}/crons", access_token)
      end
    end
  end
end
