module Travis::API::V3
  class Services::Users::Suspend < Service
    params :user_ids
    result_type :bulk_change_result

    ALLOWED_CLASSES = %w[Travis::API::V3::AccessControl::Internal]

    def run!
      raise LoginRequired unless ALLOWED_CLASSES.include? access_control.class.name
      raise WrongParams unless params.include? 'user_ids'

      result query(:users).suspend(true)
    end
  end
end
