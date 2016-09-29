module Services
  module AuditTrail
    class EnableFeature < Struct.new(:current_user, :feature, :recipient)
      include Services::AuditTrail::Base

      attr_reader :current_user, :feature, :recipient

      def initialize(current_user, feature, recipient=nil)
        @current_user = current_user
        @feature = feature
        @recipient = recipient
      end

      private

      def message
        "enabled feature #{format_feature(feature)} #{recipient ? "globally" : "for " + describe(recipient)}"
      end
    end
  end
end
