# frozen_string_literal: true
require 'opencensus'
require 'opencensus/stackdriver'
require 'opencensus/trace/integrations/faraday_middleware'

class Travis::Api::App
  class Middleware
    class OpenCensus
      module Redis
        def logging(commands, &block)
          ActiveSupport::Notifications.instrument('command.redis', commands: commands) do
            return super(commands, &block)
          end
        end
      end

      ##
      # List of trace context formatters we use to parse the parent span
      # context.
      #
      # @private
      #
      AUTODETECTABLE_FORMATTERS = [
        ::OpenCensus::Trace::Formatters::CloudTrace.new,
        ::OpenCensus::Trace::Formatters::TraceContext.new
      ].freeze

      ##
      # Create the middleware.
      #
      # @param [#call] app Next item on the middleware stack
      # @param [#export] exporter The exported used to export captured spans
      #     at the end of the request. Optional: If omitted, uses the exporter
      #     in the current config.
      def initialize app, exporter: nil
        @app = app
        @exporter = exporter || ::OpenCensus::Trace.config.exporter
      end

      def self.enabled?
        ENV['OPENCENSUS_TRACING_ENABLED'] == 'true'
      end

      def self.setup
        return unless enabled?

        sampling_rate = ENV['OPENCENSUS_SAMPLING_RATE']&.to_f || 1
        ::OpenCensus.configure do |c|
          c.trace.exporter = ::OpenCensus::Trace::Exporters::Stackdriver.new
          c.trace.default_sampler = ::OpenCensus::Trace::Samplers::Probability.new sampling_rate
          c.trace.default_max_attributes = 16
          c.trace.default_max_stack_frames = 8
        end

        setup_notifications
      end

      def self.setup_notifications
        ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          unless event.payload[:cached] || event.payload[:name] == 'CACHE'
            handle_notification_event event
          end
        end
        ActiveSupport::Notifications.subscribe(/^excon\./) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          event.payload[:headers]&.delete('Authorization')
          handle_notification_event event
        end
        ActiveSupport::Notifications.subscribe('fog.aws.storage.request') do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          event.payload[:headers]&.delete('Authorization')
          handle_notification_event event
        end
        ActiveSupport::Notifications.subscribe('command.redis') do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          handle_notification_event event
        end
        ::Redis::Client.prepend Travis::Api::App::Middleware::OpenCensus::Redis
      end

      def self.handle_notification_event event
        span_context = ::OpenCensus::Trace.span_context
        if span_context
          span = span_context.start_span event.name, skip_frames: 2
          span.start_time = event.time
          span.end_time = event.end
          event.payload.each do |k, v|
            span.put_attribute "#{k}", v.to_s
          end
        end
      end

      ##
      # Run the middleware.
      #
      # @param [Hash] env The rack environment
      # @return [Array] The rack response. An array with 3 elements: the HTTP
      #     response code, a Hash of the response headers, and the response
      #     body which must respond to `each`.
      #
      def call env
        formatter = AUTODETECTABLE_FORMATTERS.detect do |f|
          env.key? f.rack_header_name
        end
        if formatter
          context = formatter.deserialize env[formatter.rack_header_name]
        end

        # TraceContextData has fields :trace_id, :span_id, :trace_options
        #
        # If trace_options is set to 0x01, this indicates that this trace
        # should always be sampled. This mechanism is also used to propagate
        # the sampling decision downstream.
        if env['HTTP_TRACE'] == 'true'
          max_trace_id = ::OpenCensus::Trace::SpanContext::MAX_TRACE_ID
          trace_id = rand 1..max_trace_id
          trace_id = trace_id.to_s(16).rjust(32, "0")
          context = ::OpenCensus::Trace::TraceContextData.new(trace_id, '', 0x01)
        end

        ::OpenCensus::Trace.start_request_trace \
        trace_context: context,
        same_process_as_parent: false do |span_context|
          begin
            span_context.in_span get_path(env) do |span|
              start_request span, env
              @app.call(env).tap do |response|
                finish_request span, response
              end
            end
          ensure
            @exporter.export span_context.build_contained_spans
          end
        end
      end

      private

      def get_path env
        path = "#{env['SCRIPT_NAME']}#{env['PATH_INFO']}"
        path = "/#{path}" unless path.start_with? "/"
        path
      end

      def get_host env
        env["HTTP_HOST"] || env["SERVER_NAME"]
      end

      def get_url env
        path = get_path env
        host = get_host env
        scheme = env["rack.url_scheme"]
        query_string = env["QUERY_STRING"].to_s
        url = "#{scheme}://#{host}#{path}"
        url = "#{url}?#{query_string}" unless query_string.empty?
        url
      end

      def start_request span, env
        span.kind = ::OpenCensus::Trace::SpanBuilder::SERVER
        span.put_attribute "app", "api"
        span.put_attribute "site", ENV["TRAVIS_SITE"]
        span.put_attribute "request_id", env["HTTP_X_REQUEST_ID"]
        span.put_attribute "http/host", get_host(env)
        span.put_attribute "http/url", get_url(env)
        span.put_attribute "http/method", env["REQUEST_METHOD"]
        span.put_attribute "http/client_protocol", env["SERVER_PROTOCOL"]
        span.put_attribute "http/user_agent", env["HTTP_USER_AGENT"]
        span.put_attribute "pid", ::Process.pid.to_s
        span.put_attribute "tid", ::Thread.current.object_id.to_s
      end

      def finish_request span, response
        if response.is_a?(::Array) && response.size == 3
          span.set_status response[0]
        end
      end
    end
  end
end
