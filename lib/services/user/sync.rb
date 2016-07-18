require 'travis/api'

module Services
  module User
    class Sync
      include Travis::API
      attr_reader :user_id

      def initialize(user_id)
        @user_id = user_id
      end

      def call
        url = "/user/#{@user_id}/sync"
        post(url)
      end
    end
  end
end
