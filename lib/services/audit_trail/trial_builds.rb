module Services
  module AuditTrail
    class TrialBuilds < Struct.new(:current_user, :owner, :builds_allowed)
      include Services::AuditTrail::Base

      def message
        'added trial builds'
      end

      def args
        { owner: owner.login, builds: builds_allowed }
      end
    end
  end
end
