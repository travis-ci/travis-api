module Services
  module AuditTrail
    class UpdateSubscription < Struct.new(:current_user, :message)
      include Services::AuditTrail::Base
    end
  end
end
