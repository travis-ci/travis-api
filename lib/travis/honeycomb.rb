# frozen_string_literal: true

require 'libhoney'

module Travis
  class Honeycomb
    class << self
      def setup
        api_requests_setup
        rpc_setup
      end

      # env vars used to configure api requests client:
      # * HONEYCOMB_ENABLED
      # * HONEYCOMB_ENABLED_FOR_DYNOS
      # * HONEYCOMB_WRITEKEY
      # * HONEYCOMB_DATASET
      # * HONEYCOMB_SAMPLE_RATE
      def api_requests
        @api_requests ||= Client.new('HONEYCOMB_')
      end

      # env vars used to configure rpc client:
      # * HONEYCOMB_RPC_ENABLED
      # * HONEYCOMB_RPC_ENABLED_FOR_DYNOS
      # * HONEYCOMB_RPC_WRITEKEY
      # * HONEYCOMB_RPC_DATASET
      # * HONEYCOMB_RPC_SAMPLE_RATE
      def rpc
        @rpc ||= Client.new('HONEYCOMB_RPC_')
      end

      def api_requests_setup
        return unless api_requests.enabled?

        Travis.logger.info 'honeycomb api requests enabled'
      end

      def rpc_setup
        return unless rpc.enabled?

        Travis.logger.info 'honeycomb rpc enabled'

        ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          event = payload.merge(
            event: name,
            duration_ms: ((finish - start) * 1000).to_i,
            id: id,
            app: 'api',
            dyno: ENV['DYNO'],
          )

          rpc.send(event)
        end

        ActiveSupport::Notifications.subscribe('request.faraday') do |name, start, finish, id, env|
          event = {
            event: name,
            duration_ms: ((finish - start) * 1000).to_i,
            id: id,
            app: 'api',
            dyno: ENV['DYNO'],
            method: env[:method],
            url: env[:url].to_s,
            host: env[:url].host,
            request_uri: env[:url].request_uri,
            request_headers: env[:request_headers].to_h,
            status: env[:status],
            response_headers: env[:response_headers].to_h,
          }

          rpc.send(event)
        end
      end
    end

    class Client
      def initialize(prefix = 'HONEYCOMB_')
        @prefix = prefix
      end

      def send(event)
        return unless enabled?

        ev = honey.event
        ev.add(event)
        ev.send
      end

      def enabled?
        return @enabled unless @enabled.nil?
        @enabled = (
          env('ENABLED') == 'true' ||
          env('ENABLED_FOR_DYNOS')&.split(' ')&.include?(ENV['DYNO'])
        )
      end

      private

        def honey
          @honey ||= Libhoney::Client.new(
            writekey: env('WRITEKEY'),
            dataset: env('DATASET'),
            sample_rate: env('SAMPLE_RATE')&.to_i || 1
          )
        end

        def env(name)
          ENV[@prefix + name]
        end
    end
  end
end
