require 'core_ext/active_record/none_scope'
require 'travis/services/base'

module Travis
  module Services
    class FindBranches < Base
      register :find_branches

      scope_access!

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
          return scope(:build).none unless repo
          scope(:build).merge(repo.last_finished_builds_by_branches)
          # scope = scope(:build).select('DISTINCT ON (branch) id')
          # scope = scope.where(repository_id: repo.id, event_type: 'push')
          # scope = scope.group(:branch, :id)
          # scope = scope.order('branch, finished_at DESC')
          # scope(:build).where(id: scope).limit(50).order('finished_at DESC')
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end
    end
  end
end
