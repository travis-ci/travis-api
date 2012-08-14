require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Profile < Endpoint
      # Gives information about the currently logged in user.
      #
      # Example:
      #
      #     {
      #       "user": {
      #         "email": "svenfuchs@artweb-design.de",
      #         "gravatar_id": "402602a60e500e85f2f5dc1ff3648ecb",
      #         "is_syncing": false,
      #         "locale": "de",
      #         "login": "svenfuchs",
      #         "name": "Sven Fuchs",
      #         "synced_at": "2012-08-14T22:11:21Z"
      #       }
      #     }
      get('/', scope: :private) { body(user) }

      # TODO: Add implementation and documentation.
      post('/sync', scope: :private) { raise NotImplementedError }
    end
  end
end
