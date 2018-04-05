# frozen_string_literal: true
require 'opencensus/trace/integrations/rack_middleware'
require 'opencensus/stackdriver'

class Travis::Api::App
  class Middleware
    class OpenCensus
      class << self
        
        def enabled?
          ENV['OPENCENSUS_TRACING_ENABLED'] == 'true'
        end
        
        def setup
          return unless enabled?

          sampling_rate = ENV['OPENCENSUS_SAMPLING_RATE']&.to_f || 1
          ::OpenCensus.configure do |c|
            c.trace.exporter = ::OpenCensus::Trace::Exporters::Stackdriver.new
            c.trace.default_sampler = ::OpenCensus::Trace::Samplers::Probability.new sampling_rate
            c.trace.default_max_attributes = 16
          end

          setup_notifications
        end

        def setup_notifications
          ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
            event = ActiveSupport::Notifications::Event.new(*args)
            handle_notification_event event
          end
        end

        def handle_notification_event event
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
        
      end
    end
  end
end

