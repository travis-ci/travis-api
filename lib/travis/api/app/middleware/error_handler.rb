require 'travis/api/app'
require 'sentry-ruby'

class Travis::Api::App
  class Middleware
    # NOTE: ErrorHandler does not extend Base, in order to keep
    # the surface area as minimal as possible.
    class ErrorHandler < Struct.new(:app)
      def call(env)
        app.call(env)
      rescue Exception => e
        # puts("Debug issue 'app.middleware': #{e.message}")
        # puts("Backtrace:\n\t#{e.backtrace.join("\n\t")}")
        Sentry.capture_exception(e)
        raise if Travis.testing

        body = "Sorry, we experienced an error.\n"
        if env['HTTP_X_REQUEST_ID']
          body += "\n"
          body += "request_id:#{env['HTTP_X_REQUEST_ID']}\n"
        end
        [500, {'Content-Type' => 'text/plain'}, [body]]
      end
    end
  end
end
