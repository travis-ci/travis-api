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
            builds = repo.builds
            builds = builds.by_event_type(params[:event_type]) if params[:event_type]
            if params[:number]
              builds.where(:number => params[:number].to_s)
            else
              builds.older_than(params[:after_number])
            end
          elsif params[:running]
            scope_with_current_user(scope(:build).running.limit(25))
          elsif params.nil? || params == {} || params.keys.map(&:to_s) == ['access_token']
            scope_with_current_user(scope(:build).recent)
          else
            scope(:build).none
          end

          scope
        end

        def scope_with_current_user(scope)
          if !Travis.config.org? && current_user
            scope.where(repository_id: current_user.repository_ids)
          else
            scope
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
