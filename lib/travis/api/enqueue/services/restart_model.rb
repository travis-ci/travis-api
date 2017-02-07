module Travis
  module Enqueue
    module Services

      class RestartModel
        attr_reader :current_user, :target

        def initialize(current_user, params)
          @current_user = current_user
          @params = params
          target
        end

        def push(event, payload)
          if current_user && target && accept?
            ::Sidekiq::Client.push(
                  'queue'   => 'hub',
                  'class'   => 'Travis::Hub::Sidekiq::Worker',
                  'args'    => [event, payload]
                )
          end
        end

        def accept?
          current_user && permission? # && resetable?
        end

        def messages
          messages = []
          messages << { notice: "The #{type} was successfully restarted." } if accept?
          messages << { error:  'You do not seem to have sufficient permissions.' } unless permission?
          messages << { error:  "This #{type} currently can not be restarted." } unless resetable?
          messages
        end

        def type
          @type ||= @params[:build_id] ? :build : :job
        end

        def target
          if type == :build
            @target = Build.find(@params[:build_id])
          else
            @target = Job.find(@params[:job_id])
          end
        end

        private

          def permission?
            current_user.permission?(required_role, repository_id: target.repository_id)
          end

          # def resetable?
          #   target.resetable?
          # end

          def required_role
            Travis.config.roles.reset_model
          end
      end
    end
  end
end
