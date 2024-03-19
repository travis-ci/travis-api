require 'metriks'
require 'travis/support'

module Travis
  module Event
    class Handler

      # Stores metrics about domain events
      class Metrics < Handler
        EVENTS = /job:test:(started|finished)/

        def initialize(*)
          super
          @payload = Api::Serialize.data(object, type: 'job', for: 'event', version: 'v0', params: data)
        end

        def handle?
          true
        end

        def handle
          case event
          when 'job:test:started'
            events = %W(job.queue.wait_time job.queue.wait_time.#{queue})
            if job['created_at'] && job['started_at']
              meter(events, job['created_at'], job['started_at'])
            end
          when 'job:test:finished'
            events = %W(job.duration job.duration.#{queue})
            if job['started_at'] && job['finished_at']
              meter(events, job['started_at'], job['finished_at'])
            end
          end
        end

        private

          def queue
            job['queue'].gsub('.', '-')
          end

          def meter(events, started_at, finished_at)
            events.each do |event|
              if finished_at
                Metriks.timer(event).update(finished_at - started_at)
              else
                Metriks.timer(event).mark
              end
            end
          end
      end
    end
  end
end
