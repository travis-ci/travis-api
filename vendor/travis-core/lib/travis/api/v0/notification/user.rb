module Travis
  module Api
    module V0
      module Notification
        class User
          attr_reader :user

          def initialize(user, options = {})
            @user = user
          end

          def data
            {
              'user' => user_data
            }
          end

          def user_data
            {
              'id' => user.id,
              'login' => user.login
            }
          end
        end
      end
    end
  end
end
