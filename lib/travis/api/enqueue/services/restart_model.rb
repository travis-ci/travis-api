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
              'args'    => [event, payload].map! { |arg| arg.to_json }
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
          # there is no billing for .org
          return true if Travis.config.org?

          # there is no billing for .enterprise
          return true if !!Travis.config.enterprise

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
            if subscription&.active? || owner_group_subscription?
              # Owner is on a legacy plan or belongs to a group
              true
            else
              @cause_of_denial = 'You do not seem to have active subscription.'
              false
            end
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

        def subscription
          Subscription.where(owner: repository.owner)&.first
        end

        def owner_group
          repository&.owner&.owner_group
        end

        def owner_group_subscription?
          return false if owner_group.blank?

          group_owners = OwnerGroup.where(uuid: owner_group.uuid).map(&:owner)
          active_subscriptions = Subscription.where(owner: group_owners).select(&:active?)
          active_subscriptions.present?
        end

        def permission?
          current_user && current_user.permission?(required_role, repository_id: target.repository_id) && !abusive? && build_permission?
        end

        def build_permission?
          return build_permission_legacy? if Travis.config.legacy_roles

          # nil value is considered true
          return true if authorizer.for_repo(repository.id,'repository_build_restart')

          false
        rescue Travis::API::V3::AuthorizerError
          build_permission_legacy?
        end

        def build_permission_legacy?
          return false if repository.permissions.find_by(user_id: current_user.id).build == false
          return false if repository.owner_type == 'Organization' && repository.owner.memberships.find_by(user_id: current_user.id)&.build_permission == false

          true
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

        def authorizer
          @_authorizer ||= Travis::API::V3::Authorizer::new(current_user&.id)
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
