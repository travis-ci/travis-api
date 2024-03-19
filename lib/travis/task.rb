require 'faraday'
require 'core_ext/hash/compact'
require 'core_ext/hash/deep_symbolize_keys'
require 'active_support/core_ext/string'
require 'active_support/core_ext/class/attribute'

module Travis
  class Task
    include Logging
    extend  Instrumentation

    class_attribute :run_local

    class << self
      extend Exceptions::Handling

      def run(queue, *args)
        Travis::Async.run(self, :perform, async_options(queue), *args)
      end

      def run_local?
        !!run_local || Travis::Features.feature_deactivated?(:travis_tasks)
      end

      def inline_or_sidekiq
        run_local? ? :inline : :sidekiq
      end

      def async_options(queue)
        { queue: queue, use: inline_or_sidekiq, retries: 8, backtrace: true }
      end

      def perform(*args)
        new(*args).run
      end
    end

    attr_reader :payload, :params

    def initialize(payload, params = {})
      @payload = payload.deep_symbolize_keys
      @params  = params.deep_symbolize_keys
    end

    def run
      timeout after: params[:timeout] || 60 do
        process
      end
    end
    instrument :run

    private

      def repository
        @repository ||= payload[:repository]
      end

      def job
        @job ||= payload[:job]
      end

      def build
        @build ||= payload[:build]
      end

      def request
        @request ||= payload[:request]
      end

      def commit
        @commit ||= payload[:commit]
      end

      def pull_request?
        build[:pull_request]
      end

      def http
        @http ||= Faraday.new(http_options) do |conn|
          conn.request :url_encoded
          conn.use :instrumentation
          conn.use OpenCensus::Trace::Integrations::FaradayMiddleware if Travis::Api::App::Middleware::OpenCensus.enabled?
          conn.adapter :net_http_persistent
        end
      end

      def http_options
        { ssl: Travis.config.ssl.to_h }
      end

      def timeout(options = { after: 60 }, &block)
        Timeout::timeout(options[:after], &block)
      end
  end
end
