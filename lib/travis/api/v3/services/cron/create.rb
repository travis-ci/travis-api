module Travis::API::V3
  class Services::Cron::Create < Service
    result_type :cron
    params :interval, :disable_by_build

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      raise NotFound      unless branch = find(:branch, repository)
      access_control.permissions(repository).create_cron!
      Models::Cron.create(branch: branch,
                          interval: params["interval"],
                          disable_by_build: params["disable_by_build"] ? params["disable_by_build"] : false)
    end

  end
end
