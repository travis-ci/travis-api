module Travis::API::V3
  class Services::InsightsPublicKey::Latest < Service
    def run!
      raise LoginRequired unless access_control.full_access_or_logged_in?
      result query(:insights_public_key).latest(access_control.user.id)
    end
  end
end
