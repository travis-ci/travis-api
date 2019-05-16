module Travis::API::V3
  class Services::BetaMigrationRequests::Find < Service
    params :user_login

    def run!
      pp params
      raise InsufficientAccess unless access_control.full_access?
      user = User.find_by!(login: params['user_login'])
      result query.find(user)
    end
  end
end
