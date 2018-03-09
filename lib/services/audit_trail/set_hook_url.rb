module Services
  module AuditTrail
    class SetHookUrl < Struct.new(:current_user, :repository, :hook_url)
      include Services::AuditTrail::Base

      def message
        'set notification target'
      end

      def args
        { repo: repository.slug, hook: hook_url }
      end
    end
  end
end
