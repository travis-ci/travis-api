require 'travis/api'

module Services
  module User
    class Sync
      include Travis::API
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def call
        url = "/user/#{user.id}/sync"
        post(url)
      end
    end
  end
end
