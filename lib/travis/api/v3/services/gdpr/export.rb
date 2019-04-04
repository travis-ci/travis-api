module Travis::API::V3
  class Services::Gdpr::Export < Service
    def run!
      raise LoginRequired unless access_control.logged_in?
      query.export(access_control.user.id)
      no_content
    end
  end
end
