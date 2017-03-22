module Travis::API::V3
  class Services::Cron::Create < Service
    result_type :cron
    params :interval, :dont_run_if_recent_build_exists
    params :interval, :dont_run_if_recent_build_exists, prefix: :cron


    def run!
      repository = check_login_and_find(:repository)
      raise NotFound unless branch = find(:branch, repository)
      raise Error.new('Crons can only be set up for branches existing on GitHub!', status: 422) unless branch.exists_on_github
      raise Error.new('Invalid value for interval. Interval must be "daily", "weekly" or "monthly"!', status: 422) unless ["daily", "weekly", "monthly"].include?(params["interval"] || params["cron.interval"])
      access_control.permissions(repository).create_cron!
      access_control.permissions(branch.cron).delete! if branch.cron
<<<<<<< HEAD
      query.create(branch, params["interval"], params["dont_run_if_recent_build_exists"] ? params["dont_run_if_recent_build_exists"] : false)
||||||| parent of 6c243a6... Merge pull request #432 from travis-ci/cd-cron-params
      result query.create(branch, params["interval"], params["dont_run_if_recent_build_exists"] ? params["dont_run_if_recent_build_exists"] : false)
=======
      result query.create(branch)
>>>>>>> 6c243a6... Merge pull request #432 from travis-ci/cd-cron-params
    end
  end
end
