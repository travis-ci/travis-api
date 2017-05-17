require 'travis/services/base'

module Travis
  module Services
    class FindLog < Base
      register :find_log

      def run(options = {})
        result
      end

      private def result
        return Travis::RemoteLog.find_by_id(Integer(params[:id])) if params[:id]
        Travis::RemoteLog.find_by_job_id(Integer(params[:job_id]))
      end
    end
  end
end
