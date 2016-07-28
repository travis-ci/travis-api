require 'travis/services/base'

module Travis
  module Services
    class FindJobs < Base
      register :find_jobs

      def run
        preload(result)
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
          jobs.limit(250)
        end

        def preload(jobs)
          jobs = jobs.includes(:commit)
          ActiveRecord::Associations::Preloader.new(jobs, :log, :select => [:id, :job_id]).run
          ActiveRecord::Associations::Preloader.new(jobs, :repository, :select => [:id, :owner_name, :name]).run
          jobs
        end
    end
  end
end
