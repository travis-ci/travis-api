module Travis
  module Api
    module V1
      module Helpers
        module Legacy
          RESULTS = {
            passed: 0,
            failed: 1
          }

          def legacy_repository_last_build_result(repository)
            RESULTS[repository.last_build_state.try(:to_sym)]
          end

          def legacy_build_state(build)
            build.finished? ? 'finished' : build.state.to_s
          end

          def legacy_build_result(build)
            RESULTS[build.state.try(:to_sym)]
          end

          def legacy_job_state(job)
            job.finished? ? 'finished' : job.state.to_s
          end

          def legacy_job_result(job)
            RESULTS[job.state.try(:to_sym)]
          end
        end
      end
    end
  end
end
