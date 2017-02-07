module Travis::API
  # We no longer have Sinatra on every path of our middleware stack, but we've been sloppy with well fromatted responses
  # as Sinatra used to clean them up for us. This fixes it.
  class ResponseCleaner
    def initialize(app)
      @app = app
    end

    def call(env)
      status, headers, body = @app.call(env)
      if [204, 205, 304].include?(status.to_i) # stolen from Rack::Response
        headers.delete 'Content-Type'.freeze
        headers.delete 'Content-Length'.freeze
      else
        headers['Content-Type'.freeze] ||= 'application/json'.freeze
      end
      [status, headers, body]
    end
  end
end
