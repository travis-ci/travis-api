module Services
  module Repository
    class AddHookEvent
      include Travis::VCS

      attr_reader :user, :repository, :event

      def initialize(user, repository, event)
        @user = user
        @repository = repository
        @event = event
      end

      def call
        vcs.put("/repos/#{repository.id}/hook") do |request|
          request.body = { user_id: user.id, add_events: [event] }.to_json
        end
      end
    end
  end
end
