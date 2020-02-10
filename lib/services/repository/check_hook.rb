module Services
  module Repository
    class CheckHook
      include Travis::VCS

      attr_reader :repository

      def initialize(repository)
        @repository = repository
      end

      def call
        response = vcs.get("/repos/#{repository.id}/hooks") do |req|
          req.params['user_id'] = fetch_user_id
        end

        if response.success?
          JSON.parse(response.body).first
        else
          { 'error_message' => JSON.parse(response.body)['details'] }
        end
      end

      private

      def fetch_user_id
        repository.owner_type == 'User' ? repository.owner_id : nil
      end
    end
  end
end
