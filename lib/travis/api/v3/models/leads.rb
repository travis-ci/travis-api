module Travis::API::V3
  class Models::Leads
    attr_reader :id, :name, :status_label, :contacts, :custom

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @name = attributes.fetch('name')
      @status_label = attributes.fetch('status_label')
      @contacts = attributes.fetch('contacts')
      @custom = attributes.fetch('custom')
    end
  end
end
