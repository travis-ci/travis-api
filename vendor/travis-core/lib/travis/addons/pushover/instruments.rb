require 'travis/notification/instrument/event_handler'
require 'travis/notification/instrument/task'

module Travis
  module Addons
    module Pushover
      module Instruments
        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish(:users => handler.users, :api_key => handler.api_key)
          end
        end

        class Task < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<Build id=#{payload[:build][:id]}>",
              :repository => payload[:repository][:slug],
              :object_type => 'Build',
              :object_id => payload[:build][:id],
              :users => task.users,
              :message => task.message,
              :api_key => task.api_key
            )
          end
        end
      end
    end
  end
end
