require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Repositories < Endpoint
      # TODO: Add documentation.
      get '/' do
        scope = Repository.timeline.recent
        scope = scope.by_owner_name(params[:owner_name]) if params[:owner_name]
        scope = scope.by_slug(params[:slug])             if params[:slug]
        scope = scope.search(params[:search])            if params[:search].present?
        scope
      end

      # TODO: Add documentation.
      get('/:id') { Repository.find_by(params) }
    end
  end
end
