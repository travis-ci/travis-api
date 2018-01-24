require 'travis/services/base'

module Travis
  module Services
    class FindLog < Base
      register :find_log

      scope_access!

      def run(options = {})
        result
      end

      private def result
        if params[:id]
          # as we don't have the job id, we first need to get the log to check
          # permissions
          remote_log = Travis::RemoteLog.find_by_id(Integer(params[:id]))
          if remote_log && scope(:job).find_by_id(remote_log.job_id)
            remote_log
          end
        elsif params[:job_id]
          # this is only to check permissions with scope_check!
          job = scope(:job).find_by_id(params[:job_id])
          if job
            Travis::RemoteLog.find_by_job_id(Integer(params[:job_id]))
          end
        end
      end
    end
  end
end
