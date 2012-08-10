require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Builds < Endpoint
      # TODO: Add documentation.
      get '/' do
        scope = repository.builds.by_event_type(params[:event_type] || 'push')
        scope = params[:after] ? scope.older_than(params[:after]) : scope.recent
        scope
      end

      # TODO: Add documentation.
      get '/:id' do
        one = params[:repository_id] ? repository.builds : Build
        body one.includes(:commit, :matrix => [:commit, :log]).find(params[:id])
      end

      private

        def repository
          pass if params.empty?
          Repository.find_by(params) || not_found
        end
    end
  end
end
