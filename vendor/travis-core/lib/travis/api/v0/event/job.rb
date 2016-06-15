module Travis
  module Api
    module V0
      module Event
        class Job
          include Formats

          attr_reader :job

          def initialize(job, options = {})
            @job = job
            # @options = options
          end

          def data(extra = {})
            {
              'job' => job_data,
            }
          end

          private

            def job_data
              {
                'queue' => job.queue,
                'created_at' => job.created_at,
                'started_at' => job.started_at,
                'finished_at' => job.finished_at,
              }
            end
        end
      end
    end
  end
end



