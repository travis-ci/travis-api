module Travis::API::V3
  class Services::Coupons::Find < Service
    result_type :coupon

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:coupons).find(access_control.user.id, params['coupon.id'])
    end
  end
end
