require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repositories < Endpoint
      get '/' do
        respond_with all(params).run
      end

      get '/:id' do
        respond_with one(params).run
      end

      # TODO the format constraint neither seems to work nor fail?
      get '/:id/cc.:format', format: 'xml' do # v1
        respond_with one(params).run
      end

      # get '/:owner_name/:name.?:format?' do       # v1
      # get '/repos/:owner_name/:name.?:format?' do # v2
      #   respond_with service(:repositories, :one, params).run(:raise => params[:format] != 'png')
      # end
    end
  end
end
