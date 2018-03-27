module Services
  module AuditTrail
    class CancelJob < Struct.new(:current_user, :job)
      include Services::AuditTrail::Base

      def message
        'job cancelled'
      end

      def args
        { job_id: job.id }
      end
    end
  end
end
