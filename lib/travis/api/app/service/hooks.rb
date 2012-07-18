module Travis
  module Api
    class App
      class Service
        class Hooks < Service
          attr_reader :user

          def initialize(user, params)
            super(params)
            @user = user
          end

          def collection
            user.service_hooks
          end

          def update
            hook.set(payload[:active], user)
            hook
          end

          private

            def hook
              repository.service_hook
            end

            def repository
              Repository.find_or_create_by_owner_name_and_name(params[:owner_name], params[:name])
            end

            def payload
              params[:service_hook] || {}
            end
        end
      end
    end
  end
end
