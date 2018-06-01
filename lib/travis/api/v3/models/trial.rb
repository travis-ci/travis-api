module Travis::API::V3
  class Models::Trial
    include Models::Owner

    attr_reader :id, :permissions, :owner, :created_at, :status, :builds_remaining

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @permissions = Models::BillingPermissions.new(attributes.fetch('permissions'))
      @owner = fetch_owner(attributes.fetch('owner'))
      @created_at = attributes.fetch('created_at') && DateTime.parse(attributes.fetch('created_at'))
      @status = attributes.fetch('status')
      @builds_remaining = attributes.fetch('builds_remaining')
    end
  end
end
