module Travis::API::V3
  class Services::Settings::Find < Service
    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repo = find(:repository)
      find(:settings, repo)
    end
  end
end
