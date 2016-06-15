require 'travis/notification/instrument/event_handler'
require 'travis/notification/instrument/task'

module Travis
  module Addons
    module Pusher
      module Instruments
        def self.publish?(event)
          event.to_s != 'job:test:log'
        end

        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish if Instruments.publish?(handler.event)
          end
        end

        class Task < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<#{type.camelize} id=#{id}> (event: #{task.event}, channels: #{task.channels.join(', ')})",
              :object_type => type.camelize,
              :object_id => id,
              :event => task.event,
              :client_event => task.client_event,
              :channels => task.channels
            ) if Instruments.publish?(task.event)
          end

          def type
            @type ||= task.event.split(':').first
          end

          def id
            payload.key?(type.to_sym) ? payload[type.to_sym][:id] : payload[:id]
          end
        end
      end
    end
  end
end

