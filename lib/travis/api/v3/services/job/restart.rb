module Travis::API::V3
  class Services::Job::Restart < Service

    def run
      job = check_login_and_find(:job)
      access_control.permissions(job).restart!

      job.update_attribute(:debug_options, nil)
      restart_status = query.restart(access_control.user)

      if restart_status == "abuse_detected"
        abuse_detected
      else
        accepted(job: job, state_change: :restart)
      end
    end
  end
end
