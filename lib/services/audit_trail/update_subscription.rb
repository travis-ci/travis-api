module Services
  module AuditTrail
    class UpdateSubscription < Struct.new(:current_user, :message)
      include ApplicationHelper
      include Services::AuditTrail
    end
  end
end
