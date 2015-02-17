module Travis::API::V3
  class Result
    attr_accessor :type, :resource, :status

    def initialize(type, resource = [], status: 200)
      @type, @resource, @status = type, resource, status
    end

    def respond_to_missing?(method, *)
      super or method.to_sym == type.to_sym
    end

    def <<(value)
      resource << value
      self
    end

    def render
      Renderer[type].render(resource)
    end

    def method_missing(method, *args)
      return super unless method.to_sym == type.to_sym
      raise ArgumentError, 'wrong number of arguments (1 for 0)'.freeze if args.any?
      resource
    end
  end
end
