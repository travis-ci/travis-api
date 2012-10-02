module Travis::Api::App::Helpers::Responders
  class Base
    attr_reader :request, :headers, :resource, :options

    def initialize(request, headers, resource, options = {})
      @request  = request
      @headers  = headers
      @resource = resource
      @options  = options
    end
  end
end
