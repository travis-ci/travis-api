module Travis::API::V3
  class Services::SpotlightSummaryRepos::All < Service
    result_type :spotlight_summary_repos

    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:spotlight_summary_repos).all(access_control.user.id)
    end
  end
end
