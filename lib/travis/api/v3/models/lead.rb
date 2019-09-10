module Travis::API::V3
  class Models::Lead
    attr_reader :id, :name, :phones

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @name = attributes.fetch('name')
      @phones = attributes.fetch('phones')
    end
  end
end
