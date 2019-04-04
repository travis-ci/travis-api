module Travis::API::V3
  class Services::Gdpr::Purge < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      query.purge(access_control.user.id)
      no_content
    end
  end
end
