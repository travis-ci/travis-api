module Services
  module AuditTrail
    class RestartJob < Struct.new(:current_user, :job)
      include Services::AuditTrail::Base

      def message
        'job restarted'
      end

      def args
        { job_id: job.id }
      end
    end
  end
end
