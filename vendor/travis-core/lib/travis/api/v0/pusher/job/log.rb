module Travis
  module Api
    module V0
      module Pusher
        class Job
          class Log
            attr_reader :job, :options

            def initialize(job, options = {})
              @job = job
              @options = options
            end

            def data
              {
                'id' => job.id,
                'build_id' => job.source_id,
                'repository_id' => job.repository_id,
                'repository_private' => repository.private,
                '_log' => options[:_log],
                'number' => options[:number],
                'final' => options[:final]
              }
            end
          end
        end
      end
    end
  end
end

