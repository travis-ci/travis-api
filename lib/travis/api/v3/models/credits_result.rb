module Travis::API::V3
  class Models::CreditsResult
    ATTRS = %w[users minutes os instance_size credits price]

    attr_accessor *ATTRS

    def initialize(attrs)
      ATTRS.each { |key| send("#{key}=", attrs[key]) }
    end
  end
end
