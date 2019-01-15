require 'core_ext/active_record/none_scope'
require 'travis/services/base'

# v2 builds.all
#   build => commit, request, matrix.id

module Travis
  module Services
    class FindBuilds < Base
      register :find_builds

      scope_access!

      def run
        preload(result)
      end

      private

        def result
          @result ||= params[:ids] ? by_ids : by_params
        end

        def by_ids
          scope(:build).where(:id => params[:ids])
        end

        def by_params
          scope = if repo
            builds = scope(:build, repo.id).where(repository_id: repo.id)
            builds = builds.by_event_type(params[:event_type]) if params[:event_type]
            if params[:number]
              builds.where(:number => params[:number].to_s)
            else
              builds.older_than(params[:after_number])
            end
          elsif params[:running] && current_user
            scope_with_current_user(scope(:build).running.limit(25))
          elsif empty_params? && current_user
            scope_with_current_user(scope(:build).recent)
          else
            scope(:build).none
          end

          scope
        end

        def empty_params?
          params.nil? || params == {} || params.keys.map(&:to_s) == ['access_token']
        end

        def scope_with_current_user(scope)
          if Travis.config.org?
            scope
          else
            scope.where(repository_id: current_user.repository_ids)
          end
        end

        def preload(builds)
          builds.includes(:commit, :config, matrix: :config)
        end

        def repo
          @repo ||= run_service(:find_repo, params)
        end
    end
  end
end
