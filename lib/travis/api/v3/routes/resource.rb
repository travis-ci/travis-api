require 'mustermann'

module Travis::API::V3
  class Routes::Resource
    attr_accessor :identifier, :route, :services

    def initialize(identifier)
      @identifier = identifier
      @services   = {}
    end

    def add_service(request_method, service, sub_route = nil)
      sub_route &&= Mustermann.new(sub_route)
      services[[request_method, sub_route]] = service
    end

    def route=(value)
      @route = value ? Mustermann.new(value) : value
    end
  end
end
