module Services
  module AuditTrail
    class DisableFeature
      include Services::AuditTrail::Base

      attr_reader :current_user, :feature, :recipient

      def initialize(current_user, feature, recipient = NullRecipient.new)
        @current_user = current_user
        @feature = feature
        @recipient = recipient
      end

      private

      def message
        "disabled feature #{format_feature(feature)} for #{describe(recipient)}"
      end
    end
  end
end
