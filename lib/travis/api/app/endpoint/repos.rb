require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Repos < Endpoint
      # Endpoint for getting all repositories.
      #
      # You can filter the repositories by adding parameters to the request. For example, you can get all repositories
      # owned by johndoe by adding `owner_name=johndoe`, or all repositories that johndoe has access to by adding
      # `member=johndoe`. The parameter names correspond to the keys of the response hash.
      #
      # ### Response
      #
      # json(:repositories)
      get '/' do
        respond_with service(:find_repos, params)
      end

      # Gets the repository with the given id.
      #
      # ### Response
      #
      # json(:repository)
      get '/:id' do
        respond_with service(:find_repo, params)
      end

      get '/:id/cc' do
        respond_with service(:find_repo, params.merge(schema: 'cc'))
      end

      # Get the public key for the repository with the given id.
      #
      # This can be used to encrypt secure variables in the build configuration. See
      # [the encryption keys](http://about.travis-ci.org/docs/user/encryption-keys/) documentation page for more
      # information.
      #
      # ### Response
      #
      # json(:repository_key)
      get '/:id/key' do
        respond_with service(:find_repo_key, params), version: :v2
      end

      post '/:id/key' do
        respond_with service(:regenerate_repo_key, params), version: :v2
      end

      # Gets the repository with the given name.
      #
      # ### Response
      #
      # json(:repository)
      get '/:owner_name/:name' do
        Octopus.using(:follower) do
          respond_with service(:find_repo, params)
        end
      end

      # Gets the builds for the repository with the given name.
      #
      # ### Response
      #
      # json(:builds)
      get '/:owner_name/:name/builds' do
        respond_with service(:find_builds, params)
      end

      # Get a build with the given id in the repository with the given name.
      #
      # ### Response
      #
      # json(:build)
      get '/:owner_name/:name/builds/:id' do
        respond_with service(:find_build, params)
      end

      get '/:owner_name/:name/cc' do
        respond_with service(:find_repo, params.merge(schema: 'cc'))
      end

      # Get the public key for a given repository.
      #
      # This can be used to encrypt secure variables in the build configuration. See
      # [the encryption keys](http://about.travis-ci.org/docs/user/encryption-keys/) documentation page for more
      # information.
      #
      # ### Response
      #
      # json(:repository_key)
      get '/:owner_name/:name/key' do
        respond_with service(:find_repo_key, params), version: :v2
      end

      post '/:owner_name/:name/key' do
        respond_with service(:regenerate_repo_key, params), version: :v2
      end
    end
  end
end
