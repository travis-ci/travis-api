require 'travis/task'

module Travis
  module Addons
    module Archive
      class Task < Travis::Task
        def process
          Travis.run_service(:"archive_#{payload[:type]}", id: payload[:id], job_id: payload[:job_id])
        end

        class Instrument < Notification::Instrument::Task
          def run_completed
            publish(
              :msg => "for #<#{target.payload[:type].camelize} id=#{target.payload[:id]}>",
              :object_type => target.payload[:type].camelize,
              :object_id => target.payload[:id]
            )
          end
        end
        Instrument.attach_to(self)
      end
    end
  end
end
