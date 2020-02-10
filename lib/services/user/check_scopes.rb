require 'travis/api'

module Services
  module User
    class CheckScopes
      include Travis::VCS

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def call
        vcs.post("/users/#{user.id}/check_scopes")
      end
    end
  end
end

