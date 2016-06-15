module Travis
  module Api
    module V1
      module Archive
        class Build
          class Job
            include Formats

            attr_reader :job, :commit

            def initialize(job)
              @job = job
              @commit = job.commit
            end

            def data
              {
                'id' => job.id,
                'number' => job.number,
                'config' => job.obfuscated_config,
                'started_at' => format_date(job.started_at),
                'finished_at' => format_date(job.finished_at),
                'log' => job.log_content
              }
            end
          end
        end
      end
    end
  end
end
