module Services
  module Organization
    class Sync
      include Travis::API
      attr_reader :organization

      def initialize(organization)
        @organization = organization
      end

      def call
        organization.users.each do |user|
          response = Services::User::Sync.new(user).call
          response.status
        end
      end
    end
  end
end