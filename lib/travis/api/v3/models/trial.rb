module Travis::API::V3
  class Models::Trial
    attr_reader :id, :created_at, :status, :builds_remaining

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @created_at = attributes.fetch('created_at') && DateTime.parse(attributes.fetch('created_at'))
      @status = attributes.fetch('status')
      @builds_remaining = attributes.fetch('builds_remaining')
    end
  end
end
