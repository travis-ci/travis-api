require 'travis/notification/instrument/event_handler'
require 'travis/notification/instrument/task'

module Travis
  module Addons
    module Irc
      module Instruments
        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish(:channels => handler.channels)
          end
        end

        class Task < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<Build id=#{payload[:build][:id]}>",
              :repository => payload[:repository][:slug],
              # :request_id => payload['request_id'], # TODO
              :object_type => 'Build',
              :object_id => payload[:build][:id],
              :channels => task.channels,
              :messages => task.messages
            )
          end
        end
      end
    end
  end
end

