module Travis
  module Enqueue
    module Services

      class EnqueueBuild
        attr_reader :current_user, :build

        def initialize(current_user, build_id)
          @current_user = current_user
          @build = Build.find(build_id)
        end

        def push(event, payload)
          ::Sidekiq::Client.push(
                'queue'   => 'hub',
                'class'   => 'Travis::Hub::Sidekiq::Worker',
                'args'    => [event, payload]
              )
        end

        def accept?
          current_user && permission? && resetable?
        end

        def messages
          messages = []
          messages << { notice: "The build was successfully restarted." } if accept?
          messages << { error:  'You do not seem to have sufficient permissions.' } unless permission?
          messages << { error:  "This build currently can not be restarted." } unless resetable?
          messages
        end

        private

          def permission?
            current_user.permission?(required_role, repository_id: build.repository_id)
          end

          def resetable?
            build.resetable?
          end

          def required_role
            Travis.config.roles.reset_model
          end
      end
    end
  end
end
