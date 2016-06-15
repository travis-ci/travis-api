module Travis
  module Api
    module V1
      module Http
        class User
          include Formats

          attr_reader :user, :options

          def initialize(user, options = {})
            @user = user
            @options = options
          end

          def data
            {
              'login' => user.login,
              'name' => user.name,
              'email' => user.email,
              'gravatar_id' => user.gravatar_id,
              'locale' => user.locale,
              'is_syncing' => user.is_syncing,
              'synced_at' => format_date(user.synced_at)
            }
          end
        end
      end
    end
  end
end

