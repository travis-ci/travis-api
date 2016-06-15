require 'travis/notification'
require 'travis/services/base'

module Travis
  module Services
    class CancelJob < Base
      extend Travis::Instrumentation

      register :cancel_job

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
        messages << { :notice => 'The job was successfully cancelled.' } if can_cancel?
        messages << { :error  => 'You are not authorized to cancel this job.' } unless authorized?
        messages << { :error  => "The job could not be cancelled because it is currently #{job.state}." } unless job.cancelable?
        messages
      end

      def cancel
        # job may have been retrieved with a :join query, so we need to reset the readonly status
        job.send(:instance_variable_set, :@readonly, false)
        publish!
        job.cancel!
      end

      def can_cancel?
        authorized? && job.cancelable?
      end

      def authorized?
        current_user.permission?(:pull, :repository_id => job.repository_id)
      end

      def job
        @job ||= run_service(:find_job, params)
      end

      def publish!
        Travis.logger.info("Publishing cancel_job message to worker.commands queue for Job##{job.id}")
        publisher.publish(type: 'cancel_job', job_id: job.id, source: source)
      end

      private

      def publisher
        Travis::Amqp::FanoutPublisher.new('worker.commands')
      end

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            :msg => "for <Job id=#{target.job.id}> (#{target.current_user.login})",
            :result => result
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
