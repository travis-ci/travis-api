require 'travis/notification/instrument/event_handler'
require 'travis/notification/instrument/task'

module Travis
  module Addons
    module GithubStatus
      module Instruments
        class EventHandler < Notification::Instrument::EventHandler
          def notify_completed
            publish
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
              :url => task.url.to_s
            )
          end
        end
      end
    end
  end
end

