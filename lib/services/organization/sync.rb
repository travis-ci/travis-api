module Services
  module Organization
    class Sync
      include Travis::API
      attr_reader :organization, :user

      def initialize(organization)
        @organization = organization
        @user = organization.users.first
      end

      def access_token
        Travis::AccessToken.create(user: user, app_id: 2).token if user
      end

      def call
        url = "/organizations/#{organization.id}/sync"
        post(url, access_token)
      end
    end
  end
end