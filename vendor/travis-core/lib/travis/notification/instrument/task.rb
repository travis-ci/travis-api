module Travis
  module Notification
    class Instrument
      class Task < Instrument
        attr_reader :task, :payload

        def initialize(message, method, status, payload)
          @task = payload[:target]
          @payload = task.payload
          super
        end

        def run_completed
          publish
        end

        def publish(event = {})
          event[:msg] = "#{event[:msg]} #{queue_info}" if Travis::Async.enabled? && Travis::Task.run_local?
          super(event.merge(:payload => self.payload))
        end

        private

          def queue_info
            "(queue size: #{queue.items.size})" if queue
          end

          def queue
            Travis::Async::Threaded.queues[task.class.name]
          end
      end
    end
  end
end
