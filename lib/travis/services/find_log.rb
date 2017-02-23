require 'travis/logs_api'
require 'travis/services/base'

module Travis
  module Services
    class FindLog < Base
      register :find_log

      def run(options = {})
        return result_via_http if Travis.config.logs_api.enabled?
        result if result
      end

      def final?
        false
      end

      private def result
        if params[:id]
          scope(:log).find_by_id(params[:id])
        elsif params[:job_id]
          scope(:log).where(job_id: params[:job_id]).first
        end
      end

      private def result_via_http
        return logs_api.find_by_id(params[:id]) if params[:id]
        logs_api.find_by_job_id(params[:job_id])
      end

      private def logs_api
        @logs_api ||= Travis::LogsApi.new(
          url: Travis.config.logs_api.url,
          auth_token: Travis.config.logs_api.auth_token
        )
      end
    end
  end
end
