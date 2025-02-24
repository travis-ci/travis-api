module Travis::API::V3
  class Services::Organization::Unsuspend < Service
    params :id, :user_ids
    result_type :bulk_change_result

    ALLOWED_CLASSES = %w[Travis::API::V3::AccessControl::Internal Travis::API::V3::AccessControl::OrgToken]

    def run!
      raise LoginRequired unless ALLOWED_CLASSES.include? access_control.class.name

      if access_control.class.name == 'Travis::API::V3::AccessControl::OrgToken'
        raise LoginRequired unless access_control.visible?('suspend')
      end

      raise WrongParams unless params.include? 'user_ids'

      result query(:organization).suspend(false)
    end
  end
end
