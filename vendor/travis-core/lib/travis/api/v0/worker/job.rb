module Travis
  module Api
    module V0
      module Worker
        class Job
          require 'travis/api/v0/worker/job/test'

          attr_reader :job

          def initialize(job, options = {})
            @job = job
          end

          def commit
            job.commit
          end

          def repository
            job.repository
          end

          def request
            build.request
          end

          def build
            job.source
          end
        end
      end
    end
  end
end
