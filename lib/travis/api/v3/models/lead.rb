module Travis::API::V3
  class Models::Lead
    attr_reader :id, :name, :emails, :phones

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @name = attributes.fetch('name')
      @emails = attributes.fetch('emails')
      @phones = attributes.fetch('phones')
    end
  end
end
