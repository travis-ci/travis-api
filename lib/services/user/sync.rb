require 'travis/api'

module Services
  module User
    class Sync
      include Travis::API
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def access_token
        Travis::AccessToken.create(user: user, app_id: 2).token if user
      end

      def call
        url = "/user/#{user.id}/sync"
        post(url, access_token)
      end
    end
  end
end
