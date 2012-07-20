module Travis
  module Api
    class App
      class Service
        class Profile < Service
          attr_reader :user

          def initialize(user)
            @user = user
          end

          def item
            user
          end

          def sync
            unless user.is_syncing?
              publisher.publish({ user_id: user.id }, type: 'sync')
              user.update_attribute(:is_syncing, true)
            end
          end

          private

            def publisher
              Travis::Amqp::Publisher.new('sync.user')
            end
        end
      end
    end
  end
end
