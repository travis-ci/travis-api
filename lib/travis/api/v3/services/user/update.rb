module Travis::API::V3
  class Services::User::Update < Service
    result_type :user
    params :utm_params

    def run!
      raise LoginRequired unless access_control.logged_in? && access_control.user

      Models::UserUtmParam.new(
        utm_data: params["utm_params"],
        user: access_control.user
      ).save

      result(user)
    end
  end
end
