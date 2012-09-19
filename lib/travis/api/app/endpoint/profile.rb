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
      get '/', scope: :private do
        body service(:user).find_one, type: :user
      end

      put '/', scope: :private do
        raise NotImplementedError
        update_locale if valid_locale?
        'ok'
      end

      # TODO: Add implementation and documentation.
      # , scope: :private
      post '/sync' do
        # raise NotImplementedError
        # sync_user(current_user)
        'ok'
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
          params[:user][:locale]
        end

        def valid_locale?
          I18n.available_locales.include?(locale.to_sym) # ???
        end

        def update_locale
          current_user.update_attributes!(:locale => locale.to_s)
          session[:locale] = locale # ???
        end
    end
  end
end
