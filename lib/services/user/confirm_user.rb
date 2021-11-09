require 'travis/api'

module Services
  module User
    class ConfirmUser
      include Travis::VCS

      def initialize(user)
        @user = user
      end

      def call
        vcs.post('/users/confirm') do |request|
          request.body = { token: @user.confirmation_token }.to_json
        end
      end
    end
  end
end
