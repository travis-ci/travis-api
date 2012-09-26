require 'travis/api/app'

class Travis::Api::App
  class Endpoint
    class Profile < Endpoint
      LOCALES = %w(en es fr ja eb nl pl pt-Br ru) # TODO how to figure these out

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
      get '/', scope: :private do
        body service(:user).find_one, type: :user
      end

      put '/:id?', scope: :private do
        update_locale if valid_locale?
        'ok'
      end

      # TODO: Add implementation and documentation.
      post '/sync', scope: :private do
        sync_user(current_user)
        204
      end

      private

        def sync_user(user)
          unless user.is_syncing?
            publisher = Travis::Amqp::Publisher.new('sync.user')
            publisher.publish({ user_id: user.id }, type: 'sync')
            user.update_column(:is_syncing, true)
          end
        end

        def locale
          params[:profile][:locale].to_s
        end

        def valid_locale?
          LOCALES.include?(locale)
        end

        def update_locale
          current_user.update_attribute(:locale, locale.to_s)
          # session[:locale] = locale # ???
        end
    end
  end
end

