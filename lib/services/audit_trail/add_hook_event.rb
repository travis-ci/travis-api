module Services
  module AuditTrail
    class AddHookEvent < Struct.new(:current_user, :repository, :event)
      include Services::AuditTrail::Base

      def message
        'added hook event'
      end

      def args
        { event: event, repo: repository.slug }
      end
    end
  end
end
