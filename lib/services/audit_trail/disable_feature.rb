module Services
  module AuditTrail
    class DisableFeature
      include Services::AuditTrail::Base

      attr_reader :current_user, :feature, :recipient

      def initialize(current_user, feature, recipient=nil)
        @current_user = current_user
        @feature = feature
        @recipient = recipient
      end

      private

      def message
        "disabled feature #{format_feature(feature)} #{recipient ? "for " + describe(recipient) : "globally"}"
      end
    end
  end
end
