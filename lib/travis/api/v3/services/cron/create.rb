module Travis::API::V3
  class Services::Cron::Create < Service
    result_type :cron
    params :interval, :disable_by_build

    def run!
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless repository = find(:repository)
      raise NotFound      unless branch = find(:branch, repository)
      raise Error.new('Invalid value for interval. Interval must be "daily", "weekly" or "monthly"!', status: 422) unless ["daily", "weekly", "monthly"].include?(params["interval"])
      access_control.permissions(repository).create_cron!

      if branch.cron
        access_control.permissions(branch.cron).delete!
      end

      query.create(branch, params["interval"], params["disable_by_build"] ? params["disable_by_build"] : false)

    end

  end
end
