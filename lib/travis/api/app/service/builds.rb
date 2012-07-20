module Travis
  module Api
    class App
      class Service
        class Builds < Service
          def collection
            scope = repository.builds.by_event_type(params[:event_type] || 'push')
            scope = params[:after] ? scope.older_than(params[:after]) : scope.recent
            scope
          end

          def item
            one = params[:repository_id] ? repository.builds : Build
            one.includes(:commit, :matrix => [:commit, :log]).find(params[:id])
          end

          private

            def repository
              Repository.find_by(params) || not_found # TODO needs to return nil if params are empty
            end
        end
      end
    end
  end
end

