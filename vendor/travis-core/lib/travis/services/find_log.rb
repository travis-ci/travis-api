require 'travis/services/base'

module Travis
  module Services
    class FindLog < Base
      register :find_log

      def run(options = {})
        result if result
      end

      def final?
        # TODO jobs can be requeued, so finished jobs are no more final
        # result && result.job && result.job.finished?
        false
      end

      # def updated_at
      #   result.updated_at
      # end

      private

        def result
          @result ||= if params[:id]
            scope(:log).find_by_id(params[:id])
          elsif params[:job_id]
            scope(:log).where(job_id: params[:job_id]).first
          end
        end
    end
  end
end
