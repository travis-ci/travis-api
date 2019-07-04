module Services
  module Organization
    class Sync
      attr_reader :organization

      def initialize(organization)
        @organization = organization
      end

      def call
        ::Sidekiq::Client.push(
          'queue' => 'sync',
          'class' => 'Travis::GithubSync::Worker',
          'args' => [:sync_org, { org_id: organization.id }, full: true]
        )
      end
    end
  end
end
