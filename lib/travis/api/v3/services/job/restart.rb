module Travis::API::V3
  class Services::Job::Restart < Service

    def run
      job = check_login_and_find(:job)
      access_control.permissions(job).restart!

      job.update_attribute(:debug_options, nil)
      query.restart(access_control.user)
      accepted(job: job, state_change: :restart)
    end
  end
end
