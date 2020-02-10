module Services
  module Organization
    class Sync
      include Travis::VCS

      attr_reader :organization

      def initialize(organization)
        @organization = organization
      end

      def call
        vcs.post("/organizations/#{organization.id}/sync_data")
      end
    end
  end
end
