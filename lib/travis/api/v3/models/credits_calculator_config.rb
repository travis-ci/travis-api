module Travis::API::V3
  class Models::CreditsCalculatorConfig
    ATTRS = %w[users minutes os instance_size]

    attr_accessor *ATTRS

    def initialize(attrs)
      ATTRS.each { |key| send("#{key}=", attrs[key]) }
    end
  end
end
