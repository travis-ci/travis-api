require 'travis/api/app'
require 'sentry-ruby'

class Travis::Api::App
  class Middleware
    # NOTE: ErrorHandler does not extend Base, in order to keep
    # the surface area as minimal as possible.
    class ErrorHandler < Struct.new(:app)
      def call(env)
        app.call(env)
      rescue Travis::API::V3::TimeoutError => e
        Sentry.capture_exception(e)
        raise if Travis.testing

        body = e.message
        if env['HTTP_X_REQUEST_ID']
          body += "\n"
          body += "request_id:#{env['HTTP_X_REQUEST_ID']}\n"
        end
        [504, {'Content-Type' => 'text/plain'}, [body]]
      rescue Exception => e
        Sentry.capture_exception(e)
        raise if Travis.testing

        body = "Sorry, we experienced an error."
        if env['HTTP_X_REQUEST_ID']
          body += "\n"
          body += "request_id:#{env['HTTP_X_REQUEST_ID']}\n"
        end

        [500, {'Content-Type' => 'text/plain'}, [body]]
      end
    end
  end
end
