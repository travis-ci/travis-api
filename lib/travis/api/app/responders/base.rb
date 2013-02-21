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

    def send_file(*args)
      endpoint.send_file(*args)
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

    def apply?
      acceptable_format?
    end

    def format
      self.class.name.split('::').last.downcase
    end

    def acceptable_format?
      if accept = options[:accept]
        accept.accepts?(Rack::Mime.mime_type(".#{format}"))
      end
    end
  end
end
