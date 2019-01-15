module Travis::API::V3
  class Models::Invoice
    attr_reader :id, :created_at, :url

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @created_at = attributes.fetch('created_at') && DateTime.parse(attributes.fetch('created_at'))
      @url = attributes.fetch('url')
    end
  end
end
