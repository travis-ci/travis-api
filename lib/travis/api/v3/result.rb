module Travis::API::V3
  class Result
    attr_accessor :type, :resource

    def initialize(type, resource = [])
      @type, @resource = type, resource
    end

    def respond_to_missing?(method, *)
      super or method.to_sym == type.to_sym
    end

    def <<(value)
      resource << value
      self
    end

    def method_missing(method, *args)
      return super unless method.to_sym == type.to_sym
      raise ArgumentError, 'wrong number of arguments (1 for 0)'.freeze if args.any?
      resource
    end
  end
end
