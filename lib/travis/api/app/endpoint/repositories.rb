require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO: Add documentation.
    class Repositories < Endpoint
      # TODO: Add documentation.
      get '/' do
        body service(:repositories).find_all(params)
      end

      # TODO: Add documentation.
      get('/:id') do
        body service(:repositories).find_one(params)
      end

      # TODO make sure status images and cc.xml work
      # rescue ActiveRecord::RecordNotFound
      #   raise unless params[:format] == 'png'
    end
  end
end
