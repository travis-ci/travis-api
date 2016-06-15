require 'travis/support/instrumentation'
require 'travis/services/base'

module Travis
  module Services
    class UpdateLog < Base
      extend Travis::Instrumentation

      register :update_log

      def run
        log = run_service(:find_log, id: params[:id])
        log.update_attributes(archived_at: params[:archived_at], archive_verified: params[:archive_verified]) if log
      end
      instrument :run

      class Instrument < Notification::Instrument
        def run_completed
          publish(
            msg: "for #<Log id=#{target.params[:id]}> params=#{target.params.inspect}",
            object_type: 'Log',
            object_id: target.params[:id],
            params: target.params,
            result: result
          )
        end
      end
      Instrument.attach_to(self)
    end
  end
end
