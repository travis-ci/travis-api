module Travis::API::V3
  class Services::Organization::Suspend < Service
    params :id, :user_ids, :vcs_type, :vcs_ids
    result_type :bulk_change_result

    ALLOWED_CLASSES = %w[Travis::API::V3::AccessControl::Internal Travis::API::V3::AccessControl::OrgToken]

    def run!
      raise LoginRequired unless ALLOWED_CLASSES.include? access_control.class.name

      if access_control.class.name == 'Travis::API::V3::AccessControl::OrgToken'
        raise LoginRequired unless access_control.visible?('suspend')
      end

      raise WrongParams unless valid_params?

      result query(:organization).suspend(true)
    end

    private def valid_params?
      params.include?('user_ids') || ( params.include?('vcs_type') && params.include?('vcs_ids') )
    end
  end
end
