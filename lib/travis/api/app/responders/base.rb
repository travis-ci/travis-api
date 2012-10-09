module Travis::Api::App::Responders
  class Base
    attr_reader :endpoint, :resource, :options

    def initialize(endpoint, resource, options = {})
      @endpoint = endpoint
      @resource = resource
      @options  = options
    end

    def halt(*args)
      endpoint.halt(*args)
    end

    def flash
      endpoint.flash
    end

    def request
      endpoint.request
    end

    def params
      endpoint.params
    end

    def headers
      endpoint.headers
    end
  end
end
