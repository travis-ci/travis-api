module Travis
  module Enqueue
    module Services

      class CancelModel

        attr_reader :current_user, :target

        def initialize(current_user, params)
          @current_user = current_user
          @params = params
          target
        end

        def messages
          messages = []
          messages << { :notice => "The #{type} was successfully cancelled." } if can_cancel?
          messages << { :error  => "You are not authorized to cancel this #{type}." } unless authorized?
          messages << { :error  => "The #{type} could not be cancelled." } unless build.cancelable?
          messages
        end

        def push(event, payload)
          # target may have been retrieved with a :join query, so we need to reset the readonly status
          if can_cancel?
            ::Sidekiq::Client.push(
                  'queue'   => 'hub',
                  'class'   => 'Travis::Hub::Sidekiq::Worker',
                  #'args'    => ["#{type}:cancel", @params]
                  'args'    => [event, payload].map! { |arg| arg.to_json}
                )
          end
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

        def can_cancel?
          authorized? && target.cancelable?
        end

        # check on web
        def authorized?
          current_user.permission?(:pull, :repository_id => target.repository_id)
        end

      end
    end
  end
end
