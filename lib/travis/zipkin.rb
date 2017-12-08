# frozen_string_literal: true

require 'zipkin-tracer'

# some of this code is borrowed from
# zipkin-ruby/lib/zipkin-tracer/trace_client.rb

module Travis
  class Zipkin
    class SqlListener
      def start(name, id, payload)
        return unless Trace.tracer && ZipkinTracer::TraceContainer.current

        trace_id = ZipkinTracer::TraceGenerator.new.next_trace_id
        span = Trace.tracer.start_span(trace_id, 'sql')

        span.record payload[:name]
        span.record_tag('sql', payload[:sql], Trace::BinaryAnnotation::Type::STRING)
        span.record_tag('binds', payload[:binds].to_json, Trace::BinaryAnnotation::Type::STRING)
        span.record_tag('cached', payload[:cached], Trace::BinaryAnnotation::Type::BOOL)
        span.record(Trace::Annotation::CLIENT_SEND)

        span_stack = Thread.current[:_zipkin_span_stack] ||= []
        span_stack.push span
      end

      def finish(name, id, payload)
        return unless Trace.tracer && ZipkinTracer::TraceContainer.current

        span_stack = Thread.current[:_zipkin_span_stack]
        span = span_stack.pop

        span.record(Trace::Annotation::CLIENT_RECV)

        Trace.tracer.end_span(span)
      end
    end

    class << self
      def setup
        ActiveSupport::Notifications.subscribe('sql.active_record', SqlListener.new)
      end
    end
  end
end
