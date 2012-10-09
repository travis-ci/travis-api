require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repos < Endpoint
      get '/' do
        respond_with service(:repositories, :all, params)
      end

      get '/:id' do
        respond_with service(:repositories, :one, params)
      end

      get '/:id/cc' do
        respond_with service(:repositories, :one, params.merge(schema: 'cc'))
      end

      get '/:owner_name/:name' do
        respond_with service(:repositories, :one, params)
      end

      get '/:owner_name/:name/builds' do
        respond_with service(:builds, :all, params)
      end

      get '/:owner_name/:name/builds/:id' do
        respond_with service(:builds, :one, params)
      end
    end
  end
end
