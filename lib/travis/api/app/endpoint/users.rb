require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    # TODO should this be /profile?
    class Users < Endpoint
      before { authenticate_by_mode! }

      # Gives information about the currently logged in user.
      #
      # Example:
      #
      #     {
      #       "user": {
      #         "name": "Sven Fuchs",
      #         "login": "svenfuchs",
      #         "email": "svenfuchs@artweb-design.de",
      #         "gravatar_id": "402602a60e500e85f2f5dc1ff3648ecb",
      #         "locale": "de",
      #         "is_syncing": false,
      #         "synced_at": "2012-08-14T22:11:21Z"
      #       }
      #     }
      get '/', scope: :private do
        respond_with current_user, type: :user
      end

      get '/permissions', scope: :private do
        respond_with service(:find_user_permissions), type: :permissions
      end

      # TODO fix url/key generation in ember-data
      # get '/accounts', scope: :private do
      #   respond_with service(:users, :find_accounts), type: :accounts
      # end

      # TODO fix url/key generation in ember-data
      # get '/broadcasts', scope: :private do
      #   respond_with service(:users, :find_broadcasts), type: :broadcasts
      # end

      get '/:id', scope: :private do
        pass unless current_user.id.to_s == params[:id]
        respond_with current_user, type: :user
      end

      put '/:id?', scope: :private do
        respond_with service(:update_user, params[:user]), type: :user
      end

      post '/sync', scope: :private do
        if current_user.syncing?
          status 409
          { 'message' => "Sync already in progress. Try again later." }
        else
          respond_with service(:sync_user)
        end
      end
    end
  end
end
