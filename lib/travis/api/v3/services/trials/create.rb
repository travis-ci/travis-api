module Travis::API::V3
    class Services::Trials::Create < Service
    params :owner, :type

    def run!
        raise LoginRequired unless access_control.full_access_or_logged_in?
        result query(:trials).create(access_control.user.id), status: 202 
    end
  end
end
