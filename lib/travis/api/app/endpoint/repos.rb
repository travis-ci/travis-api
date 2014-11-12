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
        prefer_follower do
          respond_with service(:find_repos, params)
        end
      end

      # Retrieves repositories for a given owner.
      get '/:owner_name' do
        pass if params[:owner_name] =~ /^\d+$/ # so we don't capture '/:id'
        prefer_follower do
          respond_with service(:find_repos, params)
        end
      end

      # Gets the repository with the given id.
      #
      # ### Response
      #
      # json(:repository)
      get '/:id' do
        prefer_follower do
          respond_with service(:find_repo, params)
        end
      end

      get '/:id/cc' do
        respond_with service(:find_repo, params.merge(schema: 'cc'))
      end

      # Get settings for a given repository
      #
      get '/:id/settings', scope: :private do
        settings = service(:find_repo_settings, params).run
        if settings
          respond_with({ settings: settings.simple_attributes }, version: :v2)
        else
          status 404
        end
      end

      patch '/:id/settings', scope: :private do
        payload = JSON.parse request.body.read

        if payload['settings'].blank? || !payload['settings'].is_a?(Hash)
          halt 422, { "error" => "Settings must be passed with a request" }
        end

        settings = service(:find_repo_settings, params).run
        if settings
          settings.merge(payload['settings'])
          # TODO: I would like to have better API here, but leaving this
          # for testing to not waste too much time before I can play with it
          if settings.save
            respond_with({ settings: settings.simple_attributes }, version: :v2)
          else
            status 422
            respond_with(settings, type: :validation_error, version: :v2)
          end
        else
          status 404
        end
      end

      # Get the public key for the repository with the given id.
      #
      # This can be used to encrypt secure variables in the build configuration. See
      # [the encryption keys](http://docs.travis-ci.com/user/encryption-keys/) documentation page for more
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

      # Gets list of branches
      get '/:repository_id/branches' do
        respond_with service(:find_branches, params), type: :branches, version: :v2
      end

      # Gets latest build on a branch
      get '/:repository_id/branches/*' do
        params[:branch] = params[:splat]
        respond_with service(:find_branch, params), type: :branch, version: :v2
      end

      # List caches for a given repo. Can be filtered with `branch` and `match` query parameter.
      get '/:repository_id/caches', scope: :private do
        respond_with service(:find_caches, params), type: :caches, version: :v2
      end

      # Delete caches for a given repo. Can be filtered with `branch` and `match` query parameter.
      delete '/:repository_id/caches', scope: :private do
        respond_with service(:delete_caches, params), type: :caches, version: :v2
      end

      # Gets the repository with the given name.
      #
      # ### Response
      #
      # json(:repository)
      get '/:owner_name/:name' do
        prefer_follower do
          respond_with service(:find_repo, params)
        end
      end

      # Gets the builds for the repository with the given name.
      #
      # ### Response
      #
      # json(:builds)
      get '/:owner_name/:name/builds' do
        name = params[:branches] ? :find_branches : :find_builds
        params['ids'] = params['ids'].split(',') if params['ids'].respond_to?(:split)
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
      # [the encryption keys](http://docs.travis-ci.com/user/encryption-keys/) documentation page for more
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

      # Gets list of branches
      get '/:owner_name/:name/branches' do
        respond_with service(:find_branches, params), type: :branches, version: :v2
      end

      # Gets latest build on a branch
      get '/:owner_name/:name/branches/*' do
        params[:branch] = params[:splat]
        respond_with service(:find_branch, params), type: :branch, version: :v2
      end

      # List caches for a given repo. Can be filtered with `branch` and `match` query parameter.
      get '/:owner_name/:name/caches', scope: :private do
        respond_with service(:find_caches, params), type: :caches, version: :v2
      end

      # Delete caches for a given repo. Can be filtered with `branch` and `match` query parameter.
      delete '/:owner_name/:name/caches', scope: :private do
        respond_with service(:delete_caches, params), type: :caches, version: :v2
      end
    end
  end
end
