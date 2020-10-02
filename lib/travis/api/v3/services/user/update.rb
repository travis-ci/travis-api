module Travis::API::V3
  class Services::User::Update < Service
    result_type :user
    params :utm_params

    def run!
      raise LoginRequired unless access_control.logged_in? && access_control.user
      raise WrongParams if utm_data.empty?

      Models::UserUtmParam.new(
        utm_data: utm_data,
        user: access_control.user
      ).save

      result(access_control.user)
    end

    private

    def utm_data
      json = params["utm_params"]
      return {} unless json.is_a?(Hash)
      json.filter { |key| key.start_with?("utm_") }
    end
  end
end
