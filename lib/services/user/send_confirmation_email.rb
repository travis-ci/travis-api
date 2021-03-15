require 'travis/api'

module Services
  module User
    class SendConfirmationEmail
      include Travis::VCS

      def initialize(user)
        @user = user
      end

      def call
        vcs.post('/users/request_confirmation') do |request|
          request.body = { id: @user.id }.to_json
        end
      end
    end
  end
end
