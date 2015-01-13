module Travis::API::V3
  class Router
    not_found = '{"error":{"message":"not found"}}'.freeze
    headers   = { 'Content-Type'.freeze => 'application/json'.freeze, 'X-Cascade'.freeze => 'pass'.freeze, 'Content-Length'.freeze => not_found.bytesize }
    NOT_FOUND = [ 404, headers, not_found ]

    attr_accessor :routs, :not_found

    def initialize(routes = Routes, not_found: NOT_FOUND)
      @routes    = routes
      @not_found = not_found
    end

    def call(env)
      access_control = AccessControl.new(env)
      p access_control
      not_found
    end
  end
end
