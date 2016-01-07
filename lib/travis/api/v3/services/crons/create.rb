module Travis::API::V3
  class Services::Crons::Create < Service
    result_type :cron
    params :type, :disable_by_build

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      raise NotFound      unless branch = find(:branch, repository)
      access_control.permissions(repository).create_cron!
      Models::Cron.create(branch: branch,
                          type:   params["type"],
                          disable_by_build: value("disable_by_build"))
    end

    def value s
      params[s] ? params[s] : false
    end

  end
end
