require 'travis/services/base'

module Travis
  module Services
    class FindJobs < Base
      register :find_jobs

      scope_access!

      def run
        result
      end

      private

        def result
          @result ||= params[:ids] ? by_ids : by_params
        end

        def by_ids
          scope(:job).where(:id => params[:ids])
        end

        def by_params
          jobs = scope(:job)
          if params[:state]
            jobs = jobs.where(state: params[:state])
          else
            jobs = jobs.where(state: [:created, :queued, :received, :started])
            # we don't use it anymore, but just for backwards compat
            jobs = jobs.where(queue: params[:queue]) if params[:queue]
            jobs
          end

          if !Travis.config.org? && current_user
            jobs = jobs.where(repository_id: current_user.repository_ids)
          end

          jobs.includes(:commit).limit(250)
        end
    end
  end
end
