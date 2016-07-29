require 'core_ext/active_record/none_scope'
require 'travis/services/base'

module Travis
  module Services
    class FindBranches < Base
      register :find_branches

      def run
        result
      end

      private

        def result
          @result ||= params[:ids] ? by_ids : by_params
        end

        def by_ids
          scope(:build).where(:id => params[:ids])
        end

        def by_params
          repo ? repo.last_finished_builds_by_branches : scope(:build).none
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end
    end
  end
end
