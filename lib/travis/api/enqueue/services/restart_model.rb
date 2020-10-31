module Travis
  module Enqueue
    module Services

      class RestartModel
        attr_reader :current_user, :target
        ABUSE_DETECTED = 'abuse_detected'

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

            Result.new(value: payload)
          else
            Result.new(error: @cause_of_denial || 'restart failed')
          end
        end

        def accept?
          current_user && permission? && resetable? && billing?
        end

        def billing?
          @_billing_ok ||= begin
            jobs = target.is_a?(Job) ? [target] : target.matrix

            jobs_attrs = jobs.map do |job|
              job.config ? job.config.slice(:os) : {}
            end

            client = Travis::API::V3::BillingClient.new(current_user.id)
            client.authorize_build(repository, current_user.id, jobs_attrs)
            true
          rescue Travis::API::V3::InsufficientAccess => e
            @cause_of_denial = e.message
            false
          rescue Travis::API::V3::NotFound
            # Owner is on a legacy plan
            true
          end
        end

        def messages
          messages = []
          messages << { notice: "The #{type} was successfully restarted." } if accept?
          messages << { error:  'You do not seem to have sufficient permissions.' } unless permission?
          messages << { error:  'You do not have enough credits.' } unless billing?
          messages << { error:  "This #{type} currently can not be restarted." } unless resetable?
          messages
        end

        def type
          @type ||= @params[:build_id] ? :build : :job
        end

        def repository
          target.repository
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
          current_user && current_user.permission?(required_role, repository_id: target.repository_id) && !abusive?
        end

        def abusive?
          abusive = Travis.redis.sismember("abuse:offenders", "#{@target.owner.class.name}:#{@target.owner_id}")
          @cause_of_denial = ABUSE_DETECTED if abusive
          abusive
        end

        def resetable?
          target.resetable?
        end

        def required_role
          Travis.config.roles.reset_model
        end

        class Result
          attr_reader :error, :value

          def initialize(value: nil, error: nil)
            @value = value
            @error = error
          end

          def success?
            !@error
          end
        end
      end
    end
  end
end
