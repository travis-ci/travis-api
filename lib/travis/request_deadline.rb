# frozen_string_literal: true

module Travis
  class RequestDeadline
    class ExceededError < StandardError
    end

    class Middleware
      attr_reader :app

      def initialize(app)
        @app = app
      end

      def call(env)
        if Travis::RequestDeadline.enabled?
          Travis::RequestDeadline.deadline = Time.now + Travis::RequestDeadline.interval
        end

        app.call(env)
      end
    end

    class << self
      def deadline=(deadline)
        Thread.current[:request_deadline] = deadline
      end

      def enabled?
        ENV['REQUEST_DEADLINE_ENABLED'] == 'true'
      end

      def interval
        ENV['REQUEST_DEADLINE_INTERVAL']&.to_f || 20.0
      end

      def check!
        deadline = Thread.current[:request_deadline]
        if deadline && Time.now > deadline
          raise ExceededError.new
        end
      end

      def setup
        return unless enabled?

        ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
          check!
        end
      end
    end
  end
end
