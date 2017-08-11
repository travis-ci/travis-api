require 'travis/api/app'

class Travis::Api::App
  class Middleware
    # NOTE: ErrorHandler does not extend Base, in order to keep
    # the surface area as minimal as possible.
    class ErrorHandler < Struct.new(:app)
      def call(env)
        app.call(env)
      rescue Exception => e
        [500, {'Content-Type' => 'text/plain'}, ['Sorry, we experienced an error.']]
      end
    end
  end
end
