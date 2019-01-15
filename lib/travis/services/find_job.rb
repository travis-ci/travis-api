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
          job = scope.find_by_id(params[:id])
          job.config = nil if params[:exclude_config]
          job
        end

        def scope
          scope = super(:job)
          return scope.select(params[:columns]) if params[:columns]
          columns = scope.column_names
          columns -= %w(config) if params[:exclude_config]
          columns -= %w(commit) if params[:exclude_commit]
          columns.map { |c| %("jobs"."#{c}") }
          scope = scope.includes(:config) unless params[:exclude_config]
          scope.select(columns)
        end
    end
  end
end
