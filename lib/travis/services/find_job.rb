require 'travis/services/base'

module Travis
  module Services
    class FindJob < Base
      register :find_job

      scope_access!

      def run
        result
      end

      def final?
        # TODO jobs can be requeued, so finished jobs are no more final
        # result.try(:finished?)
        false
      end

      def updated_at
        [result].map(&:updated_at).max if result
      end

      private

        def result
          @result ||= load_result
        rescue ActiveRecord::SubclassNotFound => e
          Travis.logger.warn "[services:find-job] #{e.message}"
          raise ActiveRecord::RecordNotFound
        end

        def load_result
          columns = scope(:job).column_names
          columns -= %w(config) if params[:exclude_config]
          columns = columns.map { |c| %Q{"jobs"."#{c}"} }
          scope = scope(:job).includes(:commit, :config).select(columns)
          job = scope.find_by_id(params[:id])
          job.config = nil if params[:exclude_config]
          job
        end
    end
  end
end
