module Travis::API::V3
  class Models::InsightsPublicKey
    attr_reader :key_hash, :key_body, :ordinal_value

    def initialize(attributes = {})
      @key_hash = attributes.fetch('key_hash')
      @key_body = attributes.fetch('key_body')
      @ordinal_value = attributes.fetch('ordinal_value')
    end
  end
end
