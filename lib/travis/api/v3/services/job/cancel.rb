module Travis::API::V3
  class Services::Job::Cancel < Service

    def run
      job = check_login_and_find(:job)
      return not_found if job.owner.ro_mode?

      access_control.permissions(job).cancel!
      query.cancel(access_control.user)
      accepted(job: job, state_change: :cancel)
    end
  end
end
