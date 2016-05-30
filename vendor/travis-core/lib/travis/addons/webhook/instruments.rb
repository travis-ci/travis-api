require 'travis/notification/instrument/event_handler'
require 'travis/notification/instrument/task'

module Travis
  module Addons
    module Webhook
      module Instruments
        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish(:targets => handler.targets)
          end
        end

        class Task < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<Build id=#{payload[:id]}>",
              :repository => payload[:repository].values_at(:owner_name, :name).join('/'),
              :object_type => 'Build',
              :object_id => payload[:id],
              :targets => task.targets
            )
          end
        end
      end
    end
  end
end

