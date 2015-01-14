require 'travis/api/app'
require 'skylight'
require 'skylight/probes/tilt'
require 'skylight/probes/redis'

class Travis::Api::App
  class Middleware
    class Skylight < Middleware
      set(:setup) { ::Skylight.start! }
      use ::Skylight::Middleware

      after do
        instrumenter   = ::Skylight::Instrumenter.instance
        trace          = instrumenter.current_trace if instrumenter
        trace.endpoint = "#{request.request_method} #{endpoint || request.path_info}" if trace
      end

      def endpoint
        return @endpoint if defined? @endpoint and @endpoint
        return unless headers['X-Pattern'].present? and headers['X-Endpoint'].present?
        @endpoint = Object.const_get(headers['X-Endpoint']).prefix + headers['X-Pattern']
      end
    end
  end
end
