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
      get '/:id/cc.:format', format: 'xml' do
        respond_with one(params).run
      end

      # get '/:owner_name/:name.:format', format: 'png' do
      #   pass unless params.key?('owner_name') && params.key?('name')
      #   result_image service(:repositories, :one, params).run(:raise => false)
      # end
    end
  end
end
