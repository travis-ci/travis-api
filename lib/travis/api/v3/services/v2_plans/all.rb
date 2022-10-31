module Travis::API::V3
  class Services::V2Plans::All < Service
    params :organization_id
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:v2_plans).all(access_control.user.id)
    end
  end
end
