# frozen_string_literal: true

require 'thread'

class Travis::Api::App
  class Middleware
    class LogTracing
      # from ActiveSupport::LogSubscriber
      CLEAR   = "\e[0m"
      BOLD    = "\e[1m"
      BLACK   = "\e[30m"
      RED     = "\e[31m"
      GREEN   = "\e[32m"
      YELLOW  = "\e[33m"
      BLUE    = "\e[34m"
      MAGENTA = "\e[35m"
      CYAN    = "\e[36m"
      WHITE   = "\e[37m"

      attr_reader :app

      class << self
        def enabled?
          ENV['LOG_TRACING_ENABLED'] == 'true'
        end

        def setup
          return unless enabled?

          ActiveSupport::Notifications.subscribe 'sql.active_record' do |*args|
            queries << args
          end
        end

        def queries
          Thread.current[:log_tracing] ||= []
        end

        def clear!
          Thread.current[:log_tracing] = []
        end
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        self.class.clear!
        begin
          @app.call(env)
        ensure
          if should_log?(env)
            log_queries!(env)
          end
        end
      end

      private def should_log?(env)
        case
        when env['HTTP_TRACE'] == 'true'
          true
        when ENV['LOG_TRACING_ENABLED_FOR_LOGIN'] && env['travis.access_token']&.user&.login == ENV['LOG_TRACING_ENABLED_FOR_LOGIN']
          true
        else
          false
        end
      end

      private def log_queries!(env)
        self.class.queries.each do |args|
          event = ActiveSupport::Notifications::Event.new *args
          duration = event.duration.round(3)

          log_line = ''
          if env['HTTP_X_REQUEST_ID']
            log_line += color("#{env['HTTP_X_REQUEST_ID']} ", YELLOW)
          end
          if event.payload[:cached]
            log_line += color("CACHE (#{duration}ms)  ", MAGENTA, true)
          else
            log_line += color("#{event.payload[:name]} (#{duration}ms)  ", MAGENTA, true)
          end
          log_line += "#{event.payload[:sql]}  "

          log_line += event.payload[:binds].map {|pair|
            column, value = pair
            [column.name, value]
          }.to_h.inspect

          Travis.logger.info log_line
        end
      end

      def color(text, color, bold = false) # :doc:
        color = self.class.const_get(color.upcase) if color.is_a?(Symbol)
        bold  = bold ? BOLD : ""
        "#{bold}#{color}#{text}#{CLEAR}"
      end
    end
  end
end
