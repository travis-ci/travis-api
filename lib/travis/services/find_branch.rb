require 'core_ext/active_record/none_scope'
require 'travis/services/base'

module Travis
  module Services
    class FindBranch < Base
      register :find_branch

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
          repo.last_build_on params[:branch] if repo and params[:branch]
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end
    end
  end
end
