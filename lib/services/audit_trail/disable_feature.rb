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

      def message
        'disabled feature'
      end

      def args
        { recipient: recipient_login, feature: feature }
      end

      def recipient_login
        recipient.respond_to?(:login) ? recipient.login : recipient.name
      end
    end
  end
end
