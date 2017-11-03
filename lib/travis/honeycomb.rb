# frozen_string_literal: true

require 'libhoney'
require 'thread'

module Travis
  class Honeycomb
    class << self
      def context
        Thread.current[:honeycomb_context] ||= Context.new
      end

      def setup
        honey_setup
        sidekiq_setup
        rpc_setup
      end

      def override!
        sidekiq.override!
        rpc.override!
      end

      def clear
        context.clear
        sidekiq.clear
        rpc.clear
      end

      def honey
        @honey ||= Libhoney::Client.new
      end

      def honey_setup
        return unless sidekiq.enabled? || rpc.enabled?

        # initialize shared client
        honey
      end

      # env vars used to configure sidekiq client:
      # * HONEYCOMB_ENABLED
      # * HONEYCOMB_ENABLED_FOR_DYNOS
      # * HONEYCOMB_WRITEKEY
      # * HONEYCOMB_DATASET
      # * HONEYCOMB_SAMPLE_RATE
      def sidekiq
        Thread.current[:honeycomb_client_sidekiq] ||= Client.new('HONEYCOMB_')
      end

      # env vars used to configure rpc client:
      # * HONEYCOMB_RPC_ENABLED
      # * HONEYCOMB_RPC_ENABLED_FOR_DYNOS
      # * HONEYCOMB_RPC_WRITEKEY
      # * HONEYCOMB_RPC_DATASET
      # * HONEYCOMB_RPC_SAMPLE_RATE
      def rpc
        Thread.current[:honeycomb_client_rpc] ||= Client.new('HONEYCOMB_RPC_')
      end

      def sidekiq_setup
        return unless sidekiq.enabled?

        Travis.logger.info 'honeycomb sidekiq enabled'
      end

      def rpc_setup
        return unless rpc.enabled?

        Travis.logger.info 'honeycomb rpc enabled'

        ActiveSupport::Notifications.subscribe('sql.active_record') do |name, start, finish, id, payload|
          if rpc.should_sample?
            event = {}

            event = event.merge(Travis::Honeycomb.context.data)
            event = event.merge(payload)

            event = event.merge(
              event: name,
              duration_ms: ((finish - start) * 1000).to_i,
              id: id,
            )

            rpc.send(event)
          end
        end

        ActiveSupport::Notifications.subscribe('request.faraday') do |name, start, finish, id, env|
          if rpc.should_sample?
            event = {}

            event = event.merge(Travis::Honeycomb.context.data)

            event = event.merge(
              event: name,
              duration_ms: ((finish - start) * 1000).to_i,
              id: id,
              method: env[:method],
              url: env[:url].to_s,
              host: env[:url].host,
              request_uri: env[:url].request_uri,
              request_headers: env[:request_headers].to_h,
              status: env[:status],
              response_headers: env[:response_headers].to_h,
            )

            rpc.send(event)
          end
        end
      end
    end

    class Context
      class << self
        attr_accessor :permanent

        def add_permanent(field, value)
          @permanent ||= {}
          @permanent[field] = value
        end
      end

      def initialize
        @data = {}
      end

      def clear
        @data = {}
      end

      def add(field, value)
        @data[field] = value
      end

      def data
        (self.class.permanent || {}).merge(@data)
      end
    end

    class Client
      def initialize(prefix = 'HONEYCOMB_')
        @prefix = prefix
      end

      def send(event)
        return unless enabled? && should_sample?

        ev = Honeycomb.honey.event
        ev.add(event)
        ev.sample_rate = sample_rate
        ev.writekey = env('WRITEKEY')
        ev.dataset = env('DATASET')
        ev.send_presampled
      end

      def enabled?
        return @enabled unless @enabled.nil?
        @enabled = (
          env('ENABLED') == 'true' ||
          env('ENABLED_FOR_DYNOS')&.split(' ')&.include?(ENV['DYNO'])
        )
      end

      def should_sample?
        sample_result.should_sample
      end

      def sample_rate
        sample_result.sample_rate
      end

      def override!
        @override = true
      end

      def clear
        @override = false
        @sample_result = nil
      end

      private def sample_result
        @sample_result ||= sampler.call
      end

      private def sampler
        if @override
          yes_sampler
        else
          random_sampler
        end
      end

      private def yes_sampler
        @yes_sampler ||= YesSampler.new
      end

      private def random_sampler
        @random_sampler ||= RandomSampler.new(default_sample_rate)
      end

      private def default_sample_rate
        @default_sample_rate ||= env('SAMPLE_RATE')&.to_i || 1
      end

      private def env(name)
        ENV[@prefix + name]
      end
    end

    class YesSampler
      def call
        SamplerResult.new(true, 1)
      end
    end

    class RandomSampler
      def initialize(default_sample_rate)
        @default_sample_rate = default_sample_rate
      end

      def call
        should_sample = rand(1..@default_sample_rate) == 1
        SamplerResult.new(should_sample, @default_sample_rate)
      end
    end

    class SamplerResult < Struct.new(:should_sample, :sample_rate)
    end
  end
end
