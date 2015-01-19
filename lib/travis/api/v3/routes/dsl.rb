require 'travis/api/v3/routes/resource'
require 'mustermann'

module Travis::API::V3
  module Routes::DSL
    def resources
      @resources ||= []
    end

    def current_resource
      @current_resource ||= nil
    end

    def resource(type, &block)
      resource = Routes::Resource.new(type)
      with_resource(resource, &block)
      resources << resource
    end

    def with_resource(resource)
      resource_was, @current_resource = current_resource, resource
      yield
    ensure
      @current_resource = resource_was
    end

    def route(value)
      current_resource.route = Mustermann.new(value)
    end

    def get(*args)
      current_resource.add_service('GET'.freeze, *args)
    end

    def factory_for(method, path)
    end
  end
end
