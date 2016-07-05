module Travis
  module Services
    class RemoveLog < Base
      extend Travis::Instrumentation
      include Travis::Logging

      register :remove_log

      FORMAT = "Log removed by %s at %s"

      def run
        return nil unless job

        if log.removed_at || log.removed_by
          error "Log for job #{job.id} has already been removed by #{log.removed_by} at #{log.removed_at}"
          raise LogAlreadyRemoved, "Log for job #{job.id} has already been removed"
        end

        unless authorized?
          error "Current user #{current_user} is unauthorized to remove log for job #{job.id}"
          raise AuthorizationDenied, "insufficient permission to remove logs"
        end

        unless job.finished?
          error "<Job id=#{job.id}> is not finished"
          raise JobUnfinished, "Job #{job.id} is not finished"
        end

        removed_at = Time.now

        message = FORMAT % [current_user.name, removed_at.utc]
        if params[:reason]
          message << "\n\n#{params[:reason]}"
        end

        log.clear!
        log.update_attributes!(
          :content => nil,
          :aggregated_at => nil,
          :removed_at => removed_at,
          :removed_by => current_user
        )
        log.parts.create(content: message, number: 1, final: true)
        log
      end

      instrument :run

      def log
        @log ||= job.log
      end

      def can_remove?
        authorized? && job.finished?
      end

      def authorized?
        current_user && current_user.permission?(:push, repository_id: job.repository.id)
      end

      def job
        @job ||= scope(:job).find_by_id(params[:id])
      rescue ActiveRecord::SubclassNotFound => e
        Travis.logger.warn "[services:remove-log] #{e.message}"
        raise ActiveRecord::RecordNotFound
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
