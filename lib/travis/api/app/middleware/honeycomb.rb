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
        begin
          response = @app.call(env)
          request_ended_at = Time.now
          request_time = request_ended_at - request_started_at

          honeycomb(env, response, request_time)

          response
        rescue StandardError => e
          request_ended_at = Time.now
          request_time = request_ended_at - request_started_at

          honeycomb(env, [500, {}, nil], request_time, e)

          raise e
        end
      end

      private def honeycomb(env, response, request_time, e = nil)
        status, headers, body = response

        event = {}

        event = event.merge(Travis::Honeycomb.context.data)
        event = event.merge(headers)

        request_queue = nil
        if env['HTTP_X_REQUEST_START'] && env['metriks.request.start']
          request_queue = env['metriks.request.start'].to_f*1000 - env['HTTP_X_REQUEST_START'].to_i
          request_queue = request_queue.to_i
          request_queue = request_queue > 0 ? request_queue : 0
        end

        event = event.merge({
          CONTENT_LENGTH:   headers['CONTENT_LENGTH']&.to_i,
          HTTP_STATUS:      status,
          REQUEST_TIME_MS:  request_time * 1000,
          request_queue_ms: request_queue,

          user_id:    env['travis.access_token']&.user&.id,
          user_login: env['travis.access_token']&.user&.login,

          exception_class:         e&.class&.name,
          exception_message:       e&.message,
          exception_cause_class:   e&.cause&.class&.name,
          exception_cause_message: e&.cause&.message,

          app: 'api',
          dyno: ENV['DYNO'],
          site: ENV['TRAVIS_SITE'],
        })

        event = event.merge(env_filter(env, [
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
          'HTTP_X_FORWARDED_FOR',
          'HTTP_VIA',
          'HTTP_TRAVIS_API_VERSION',
          'HTTP_HONEYCOMB_OVERRIDE',
          'HTTP_REFERER',
          'rack.attack.matched',
          'rack.attack.match_type',
        ]))

        # remove nil and blank values
        event = event.reject { |k,v| v.nil? || v == '' }

        Travis::Honeycomb.api_requests.send(event)
      end

      private def env_filter(env, keys)
        keys.map { |k| [k, env[k]] }.to_h
      end
    end
  end
end
