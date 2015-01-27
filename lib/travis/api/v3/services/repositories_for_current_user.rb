module Travis::API::V3
  class Services::RepositoriesForCurrentUser < Service
    result_type :repositories

    def run!
      raise LoginRequired unless access_control.logged_in?
      query.for_member(access_control.user)
    end
  end
end
