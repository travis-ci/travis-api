module Travis::API::V3
  class Models::Plan
    attr_reader :id, :name, :builds, :price, :currency, :annual

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @name = attributes.fetch('name')
      @builds = attributes.fetch('builds')
      @price = attributes.fetch('price')
      @currency = attributes.fetch('currency')
      @annual = attributes.fetch('annual')
    end
  end
end
