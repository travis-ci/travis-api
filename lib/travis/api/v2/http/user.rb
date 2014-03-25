module Travis
  module Api
    module V2
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
              'user' => user_data,
            }
          end

          private

            def user_data
              {
                'id' => user.id,
                'name' => user.name,
                'login' => user.login,
                'email' => user.email,
                'gravatar_id' => user.gravatar_id,
                'locale' => user.locale,
                'is_syncing' => user.syncing?,
                'synced_at' => format_date(user.synced_at),
                'correct_scopes' => user.correct_scopes?,
                'created_at' => format_date(user.created_at),
              }
            end
        end
      end
    end
  end
end


