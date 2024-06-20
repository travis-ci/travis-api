module Travis::API::V3
  class Services::CustomKeys::Create < Service
    params :owner_id, :owner_type, :name, :description, :private_key, :added_by, :public_key
    result_type :custom_key

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?

      result query(:custom_key).create(params, access_control.user)
    end
  end
end
