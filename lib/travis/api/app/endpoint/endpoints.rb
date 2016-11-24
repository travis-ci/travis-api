require 'travis/api/app'
require 'yard/sinatra'

class Travis::Api::App
  class Endpoint
    # Documents all available API endpoints for the currently deployed version.
    # Text is actually parsed from the source code upon server start.
    class Endpoints < Endpoint
      set :endpoints, {}

      set :setup do
        endpoint_files = Dir.glob(File.expand_path("../*.rb", __FILE__))

        # Only force reparse in development, as yardoc is generated the first run
        YARD::Registry.load(endpoint_files, Travis.env == 'development')

        YARD::Sinatra.routes.each do |route|
          namespace  = route.namespace
          controller = namespace.to_s.constantize
          route_info = {
            'uri'    => (controller.prefix + route.http_path).gsub('//', '/'),
            'verb'   => route.http_verb,
            'doc'    => route.docstring,
            'scope'  => /scope\W+(\w+)/.match(route.source).try(:[], 1) || controller.default_scope.to_s
          }
          endpoint   = endpoints[controller.prefix] ||= {
            'name'   => namespace.name,
            'doc'    => namespace.docstring,
            'prefix' => controller.prefix,
            'routes' => []
          }
          endpoint['routes'] << route_info
        end

        set :json, endpoints.keys.sort.map { |k| endpoints[k] }.to_json
        endpoints.each_value { |r| r[:json] = r.to_json if r.respond_to? :to_hash }
      end

      # Lists all available API endpoints by URI prefix.
      #
      # Values in the resulting array correspond to return values of
      # [`/endpoints/:prefix`](#/endpoints/:prefix).
      get '/' do
        settings.json
      end

      # Infos about a specific controller.
      #
      # Example response:
      #
      #     {
      #       name:   "Endpoints",
      #       doc:    "Documents all available API endpoints...",
      #       prefix: "/endpoints",
      #       routes: [
      #         {
      #           uri:    "/endpoints/:prefix",
      #           verb:   "GET",
      #           doc:    "Infos about...",
      #           scope:  "public"
      #         }
      #       ]
      #     }
      get '/:prefix' do |prefix|
        pass unless endpoint = settings.endpoints["/#{prefix}"]
        endpoint[:json]
      end
    end
  end
end
