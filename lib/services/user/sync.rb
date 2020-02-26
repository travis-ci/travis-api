require 'travis/api'

module Services
  module User
    class Sync
      include Travis::VCS

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def call
        vcs.post("/users/#{user.id}/sync_data")
      end
    end
  end
end
