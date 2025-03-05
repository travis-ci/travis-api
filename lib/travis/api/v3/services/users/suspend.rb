module Travis::API::V3
  class Services::Users::Suspend < Service
    params :user_ids, :vcs_type, :vcs_ids
    result_type :bulk_change_result

    ALLOWED_CLASSES = %w[Travis::API::V3::AccessControl::Internal]

    def run!
      raise LoginRequired unless ALLOWED_CLASSES.include? access_control.class.name
      raise WrongParams unless valid_params?

      result query(:users).suspend(true)
    end

    private def valid_params?
      params.include?('user_ids') || ( params.include?('vcs_type') && params.include?('vcs_ids') )
    end
  end
end
