module Travis::API::V3
  class Services::Users::Unsuspend < Service
    params :user_ids, :vcs_type, :vcs_ids
    result_type :bulk_change_result

    def run!
      raise LoginRequired unless access_control.class.name == 'Travis::API::V3::AccessControl::Internal'
      raise WrongParams unless valid_params?

      result query(:users).suspend(false)
    end

    private def valid_params?
      params.include?('user_ids') || ( params.include?('vcs_type') && params.include?('vcs_ids') )
    end
  end
end
