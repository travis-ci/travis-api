require 'travis/api/v3/routes/resource'

module Travis::API::V3
  module Routes::DSL
    def routes
      @routes ||= {}
    end

    def resources
      @resources ||= []
    end

    def current_resource
      @current_resource ||= nil
    end

    def prefix
      @prefix ||= ""
    end

    def resource(identifier, **meta_data, &block)
      resource = Routes::Resource.new(identifier, **meta_data)
      with_resource(resource, &block)
      resources << resource
    end

    def with_resource(resource)
      resource_was, @current_resource = current_resource, resource
      prefix_was, @prefix             = @prefix, resource_was.route if resource_was
      yield
    ensure
      @prefix           = prefix_was if resource_was
      @current_resource = resource_was
    end

    def route(value)
      current_resource.route = mustermann(prefix) + mustermann(value)
    end

    def mustermann(*input)
      Mustermann.new(*input, **mustermann_options)
    end

    def mustermann_options
      @mustermann_options ||= { capture: {} }
    end

    def capture(mapping)
      mapping.each_pair do |key, value|
        key = "#{current_resource.display_identifier}.#{key}" if current_resource and not key.to_s.include?(?.)
        mustermann_options[:capture][key.to_sym] = value
      end
    end

    def get(*args)
      current_resource.add_service('GET'.freeze, *args)
    end

    def post(*args)
      current_resource.add_service('POST'.freeze, *args)
    end

    def patch(*args)
      current_resource.add_service('PATCH'.freeze, *args)
    end

    def delete(*args)
      current_resource.add_service('DELETE'.freeze, *args)
    end

    def draw_routes
      resources.each do |resource|
        prefix = resource.route
        resource.services.each do |(request_method, sub_route), service|
          route = sub_route ? prefix + sub_route : prefix
          routes[route] ||= {}
          routes[route][request_method] = Services[resource.identifier][service]
        end
      end
      self.routes.replace(routes)
    end

    def factory_for(request_method, path)
      routes.each do |route, method_map|
        next unless params = route.params(path)
        raise MethodNotAllowed unless factory = method_map[request_method]
        return [factory, params]
      end
      nil # nothing matched
    end
  end
end
