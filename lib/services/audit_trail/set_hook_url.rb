module Services
  module AuditTrail
    class SetHookUrl < Struct.new(:current_user, :repository, :hook_url)
      include Services::AuditTrail::Base

      private

      def message
        "set notification target for #{repository.slug} to #{hook_url}"
      end
    end
  end
end
