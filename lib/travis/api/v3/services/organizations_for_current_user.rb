module Travis::API::V3
  class Services::OrganizationsForCurrentUser < Service
    result_type :organizations

    def run!
      raise LoginRequired unless access_control.logged_in?
      query.for_member(access_control.user)
    end
  end
end
