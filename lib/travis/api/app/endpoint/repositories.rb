require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repositories < Endpoint
      get '/' do
        body all(params).run
      end

      get('/:id') do
        body one(params).run
      end

      # TODO make sure status images and cc.xml work
      # rescue ActiveRecord::RecordNotFound
      #   raise unless params[:format] == 'png'
    end
  end
end
