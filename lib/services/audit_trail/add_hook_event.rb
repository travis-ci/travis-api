module Services
  module AuditTrail
    class AddHookEvent < Struct.new(:current_user, :repository, :event)
      include Services::AuditTrail::Base

      private

      def message
        "added hook event '#{event}' for #{repository.slug}"
      end
    end
  end
end
