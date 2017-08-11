# frozen_string_literal: true

require 'travis/honeycomb'

class Travis::Api::App
  class Middleware
    class Honeycomb
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        request_started_at = Time.now
        status, headers, response = @app.call(env)
        request_ended_at = Time.now

        event = {}

        event = event.merge(Travis::Honeycomb.context.data)
        event = event.merge(headers)

        event = event.merge({
          'CONTENT_LENGTH' => headers['CONTENT_LENGTH']&.to_i,
          'HTTP_STATUS' => status,
          'REQUEST_TIME_MS' => (request_ended_at - request_started_at) * 1000,
          'user_id' => env['travis.access_token']&.user&.id,
          'user_login' => env['travis.access_token']&.user&.login,
        })

        event = event.merge(env_filter(env, [
          'rack.version',
          'rack.multithread',
          'rack.multiprocess',
          'rack.run_once',
          'SCRIPT_NAME',
          'QUERY_STRING',
          'SERVER_PROTOCOL',
          'SERVER_SOFTWARE',
          'GATEWAY_INTERFACE',
          'REQUEST_METHOD',
          'REQUEST_PATH',
          'REQUEST_URI',
          'HTTP_VERSION',
          'HTTP_HOST',
          'HTTP_CONNECTION',
          'HTTP_CACHE_CONTROL',
          'HTTP_UPGRADE_INSECURE_REQUESTS',
          'HTTP_USER_AGENT',
          'HTTP_ACCEPT',
          'HTTP_ACCEPT_LANGUAGE',
          'REMOTE_ADDR',
        ]))

        # remove nil and blank values
        event = event.reject { |k,v| v.nil? || v == '' }

        Travis::Honeycomb.api_requests.send(event)

        [status, headers, response]
      end

      private def env_filter(env, keys)
        keys.map { |k| [k, env[k]] }.to_h
      end
    end
  end
end
