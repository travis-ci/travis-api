require 'mustermann'

module Travis::API::V3
  class Routes::Resource
    attr_accessor :identifier, :route, :services, :meta_data

    def initialize(identifier, **meta_data)
      @identifier = identifier
      @services   = {}
      @meta_data  = meta_data
    end

    def add_service(request_method, service, sub_route = nil)
      sub_route &&= Mustermann.new(sub_route)
      services[[request_method, sub_route]] = service
    end

    def route=(value)
      @route = value ? Mustermann.new(value) : value
    end

    def display_identifier
      meta_data.fetch(:as, identifier)
    end
  end
end
