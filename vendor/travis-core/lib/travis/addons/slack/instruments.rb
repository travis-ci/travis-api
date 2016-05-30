module Travis
  module Addons
    module Slack
      module Instruments
        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish(:targets => handler.targets)
          end
        end

        class Task < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<Build id=#{payload[:build][:id]}>",
              :repository => payload[:repository][:slug],
              :object_type => 'Build',
              :object_id => payload[:build][:id],
              :targets => task.targets
            )
          end
        end
      end
    end
  end
end
