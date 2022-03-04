module Services
  module AuditTrail
    class UpdateRepositorySetting
      include Services::AuditTrail::Base

      attr_reader :current_user, :repository, :setting_name, :old_value, :new_value, :reason

      def initialize(current_user, repository, setting_name, old_value, new_value, reason)
        @current_user = current_user
        @repository = repository
        @setting_name = setting_name
        @old_value = old_value
        @new_value = new_value
        @reason = reason
      end

      def message
        'updated repository setting'
      end

      def args
        {
          vcs_type: repository.vcs_type,
          slug: repository.slug,
          name: setting_name,
          old_value: old_value,
          new_value: new_value,
          reason: reason,
        }
      end
    end
  end
end
