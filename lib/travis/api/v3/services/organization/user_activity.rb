module Travis::API::V3
  class Services::Organization::UserActivity < Service
    params :id, :status, :date
    paginate(default_limit: 100)
    result_type :users

    ALLOWED_CLASSES = %w[Travis::API::V3::AccessControl::Internal Travis::API::V3::AccessControl::OrgToken]
    def run!
      raise LoginRequired unless ALLOWED_CLASSES.include? access_control.class.name

      if access_control.class.name == 'Travis::API::V3::AccessControl::OrgToken'
        raise LoginRequired unless access_control.visible?('activity')
      end

      result query(:organization).active(params['status'] != 'inactive', params['date'])
    end
  end
end
