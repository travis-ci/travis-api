module Travis::API::V3
  class Services::CreditsCalculator::DefaultConfig < Service
    result_type :credits_calculator_config

    def run!
      raise LoginRequired unless access_control.logged_in?

      result query(:credits_calculator).default_config(access_control.user.id)
    end
  end
end
