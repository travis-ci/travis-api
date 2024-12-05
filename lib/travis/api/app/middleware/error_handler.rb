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

        body = Travis::API::V3::TimeoutError.message
        if env['HTTP_X_REQUEST_ID']
          body += "\n"
          body += "request_id:#{env['HTTP_X_REQUEST_ID']}\n"
        end
        [504, {'Content-Type' => 'text/plain'}, [body]]
      rescue Exception => e
        Sentry.capture_exception(e)
        raise if Travis.testing

        if e.is_a?(Timeout::Error)
          body = "Credit card processing is currently taking longer than expected. Please check back in a few minutes and refresh the screen at that time. We apologize for the inconvenience and appreciate your patience."
        else
          body = "Sorry, we experienced an error."
        end

        if env['HTTP_X_REQUEST_ID']
          body += "\n"
          body += "request_id:#{env['HTTP_X_REQUEST_ID']}\n"
        end

        [500, {'Content-Type' => 'text/plain'}, [body]]
      end
    end
  end
end
