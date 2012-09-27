require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class User < Endpoint
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
      get '/:id?', scope: :private do
        body current_user
      end

      put '/:id?', scope: :private do
        services(:user).update_locale(locale)
        204
      end

      # TODO: Add implementation and documentation.
      post '/sync', scope: :private do
        services(:user).sync
        204
      end

      private

        def locale
          params[:profile][:locale]
        end
    end
  end
end
