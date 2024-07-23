module Travis::API::V3
  class Services::Allowance::ForOwner < Service
    def run!

      return result BillingClient.default_allowance_response if !!Travis.config.enterprise

      return result BillingClient.default_allowance_response if Travis.config.org?
      raise LoginRequired unless access_control.logged_in?

      owner = query(:owner).find

      raise NotFound unless owner
      raise InsufficientAccess unless access_control.visible?(owner)

      result query(:allowance).for_owner(owner, access_control.user.id)
    end
  end
end
