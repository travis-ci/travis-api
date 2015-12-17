module Travis::API::V3
  class Services::Crons::Create < Service
    result_type :cron
    params :mon, :tue, :wed, :thu, :fri, :sat, :sun, :disable_by_push, :hour

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      raise NotFound      unless branch = find(:branch, repository)
      access_control.permissions(repository).create_cron!
      Models::Cron.create(branch: branch,
                          mon:    value("mon"),
                          tue:    value("tue"),
                          wed:    value("wed"),
                          thu:    value("thu"),
                          fri:    value("fri"),
                          sat:    value("sat"),
                          sun:    value("sun"),
                          hour:   params["hour"],
                          disable_by_push: value("disable_by_push"))
    end

    def value s
      params[s] ? params[s] : false
    end

  end
end
