module Travis::API::V3
  class Services::CreditsCalculator::Calculator < Service
    result_type :credits_results
    params :users, :executions

    def run!
      raise LoginRequired unless access_control.logged_in?

      result query(:credits_calculator).calculate(access_control.user.id)
    end
  end
end
