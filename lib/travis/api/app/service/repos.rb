module Travis
  module Api
    class App
      class Service
        class Repos
          attr_reader :params

          def initialize(params)
            @params = params
          end

          def collection
            scope = Repository.timeline.recent
            scope = scope.by_owner_name(params[:owner_name]) if params[:owner_name]
            scope = scope.by_slug(params[:slug])             if params[:slug]
            scope = scope.search(params[:search])            if params[:search].present?
            scope
          end

          def item
            Repository.find_by(params)
          end
        end
      end
    end
  end
end
