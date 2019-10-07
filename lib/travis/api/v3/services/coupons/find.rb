module Travis::API::V3
  class Services::Coupons::Find < Service
    result_type :coupon

    def run!
      result query(:coupons).find(params['coupon.id'])
    end
  end
end
