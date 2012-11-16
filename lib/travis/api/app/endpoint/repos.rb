require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repos < Endpoint
      # Endpoint for getting all repositories.
      #
      # You can filter the repositories by adding parameters to the request. For example, you can get all repositories
      # owned by johndoe by adding `owner_name=johndoe`, or all repositories that johndoe has access to by adding
      # `member=johndoe`. The parameter names correspond to the keys of the response hash.
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

      get '/:owner_name/:name/cc' do
        respond_with service(:repositories, :find_one, params.merge(schema: 'cc'))
      end
    end
  end
end
