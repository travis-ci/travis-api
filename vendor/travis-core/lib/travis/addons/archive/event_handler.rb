require 'travis/addons/archive/task'
require 'travis/event/handler'
require 'travis/features'

module Travis
  module Addons
    module Archive
      class EventHandler < Event::Handler
        EVENTS = /log:aggregated/

        def handle?
          Travis::Features.feature_active?(:log_archiving)
        end

        def handle
          Travis::Addons::Archive::Task.run(:archive, payload)
        end

        def payload
          @payload ||= { type: type, id: object.id, job_id: object.job_id }
        end

        def type
          @type ||= event.split(':').first
        end

        class Instrument < Notification::Instrument::EventHandler
          def notify_completed
            publish(payload: handler.payload)
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
