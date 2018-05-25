require 'core_ext/active_record/none_scope'
require 'travis/services/base'

module Travis
  module Services
    class FindBranch < Base
      register :find_branch

      scope_access!

      def run
        result
      end

      def updated_at
        result.updated_at if result
      end

      private

        def result
          @result ||= params[:id] ? by_id : by_params
        end

        def by_id
          scope(:build).find(params[:id])
        end

        def by_params
          return unless repo and params[:branch]
          scope(:build).merge(repo.last_builds_on(params[:branch])).first
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end
    end
  end
end
