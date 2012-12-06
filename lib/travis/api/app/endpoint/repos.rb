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
        respond_with service(:find_repos, params)
      end

      get '/:id' do
        respond_with service(:find_repo, params)
      end

      get '/:id/cc' do
        respond_with service(:find_repo, params.merge(schema: 'cc'))
      end

      get '/:id/key' do
        respond_with service(:find_repo_key, params), version: :v2
      end

      post '/:id/key' do
        respond_with service(:regenerate_repo_key, params), version: :v2
      end

      get '/:owner_name/:name' do
        respond_with service(:find_repo, params)
      end

      get '/:owner_name/:name/builds' do
        respond_with service(:find_builds, params)
      end

      get '/:owner_name/:name/builds/:id' do
        respond_with service(:find_build, params)
      end

      get '/:owner_name/:name/cc' do
        respond_with service(:find_repo, params.merge(schema: 'cc'))
      end

      get '/:owner_name/:name/key' do
        respond_with service(:find_repo_key, params), version: :v2
      end

      post '/:owner_name/:name/key' do
        respond_with service(:regenerate_repo_key, params), version: :v2
      end
    end
  end
end
