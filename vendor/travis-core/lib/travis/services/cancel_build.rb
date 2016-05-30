require 'travis/services/base'

module Travis
  module Services
    class CancelBuild < Base
      extend Travis::Instrumentation

      register :cancel_build

      attr_reader :source

      def initialize(*)
        super

        @source = params.delete(:source) || 'unknown'
      end

      def run
        cancel if can_cancel?
      end
      instrument :run

      def messages
        messages = []
        messages << { :notice => 'The build was successfully cancelled.' } if can_cancel?
        messages << { :error  => 'You are not authorized to cancel this build.' } unless authorized?
        messages << { :error  => "The build could not be cancelled." } unless build.cancelable?
        messages
      end

      def cancel
        # build may have been retrieved with a :join query, so we need to reset the readonly status
        build.send(:instance_variable_set, :@readonly, false)
        build.cancel!
        publish!
      end

      def publish!
        # TODO: I think that instead of keeping publish logic in both cancel build
        #       and cancel job services, we could call cancel_job service for each job
        #       in the matrix, which would put build in canceled state, even without calling
        #       cancel! on build explicitly. This may be a better way to handle cancelling
        #       build
        build.matrix.each do |job|
          Travis.logger.info("Publishing cancel_job message to worker.commands queue for Job##{job.id}")
          publisher.publish(type: 'cancel_job', job_id: job.id, source: source)
        end

      end

      def can_cancel?
        authorized? && build.cancelable?
      end

      def authorized?
        current_user.permission?(:pull, :repository_id => build.repository_id)
      end

      def build
        @build ||= run_service(:find_build, params)
      end

      def publisher
        Travis::Amqp::FanoutPublisher.new('worker.commands')
      end

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            :msg => "for <Build id=#{target.build.id}> (#{target.current_user.login})",
            :result => result
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
