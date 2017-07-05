require 'travis/api/app'
require 'appsignal'

class Travis::Api::App
  class Middleware
    class Appsignal < Middleware
      set(:setup) { ::Appsignal.start! }
      use ::Appsignal::Middleware

      after do
        instrumenter   = ::Appsignal::Instrumenter.instance
        trace          = instrumenter.current_trace if instrumenter
        trace.endpoint = "#{request.request_method} #{endpoint || '???'}" if trace
      end

      def endpoint
        return @endpoint if defined? @endpoint and @endpoint
        return unless headers['X-Pattern'].present? and headers['X-Endpoint'].present?
        @endpoint = Object.const_get(headers['X-Endpoint']).prefix + headers['X-Pattern']
      rescue NameError
      end
    end
  end
end
