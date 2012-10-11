require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repos < Endpoint
      get '/' do
        respond_with service(:repositories, :find_all, params)
      end

      get '/:id' do
        respond_with service(:repositories, :find_one, params)
      end

      get '/:id/cc' do
        respond_with service(:repositories, :find_one, params.merge(schema: 'cc'))
      end

      get '/:owner_name/:name' do
        respond_with service(:repositories, :find_one, params)
      end

      get '/:owner_name/:name/builds' do
        respond_with service(:builds, :find_all, params)
      end

      get '/:owner_name/:name/builds/:id' do
        respond_with service(:builds, :find_one, params)
      end
    end
  end
end
