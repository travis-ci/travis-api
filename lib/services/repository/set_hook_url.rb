module Services
  module Repository
    class SetHookUrl
      include Travis::VCS

      attr_reader :repository, :user, :config

      def initialize(user, repository, config)
        @user = user
        @repository = repository
        @config = config
      end

      def call
        vcs.put("/repos/#{repository.id}/hook") do |request|
          request.body = { user_id: user.id, config: config }.to_json
        end
      end
    end
  end
end
