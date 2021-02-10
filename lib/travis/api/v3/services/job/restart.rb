module Travis::API::V3
  class Services::Job::Restart < Service

    def run
      job = check_login_and_find(:job)

      access_control.permissions(job).restart!
      return repo_migrated if migrated?(job.repository)

      job.update_attribute(:debug_options, nil)
      result = query.restart(access_control.user)

      Travis.logger.info "Job:Restart Debug, in Job::Restart: result = #{result}"
      if result.success?
        accepted(job: job, state_change: :restart)
      elsif result.error == Travis::Enqueue::Services::RestartModel::ABUSE_DETECTED
        abuse_detected
      else
        insufficient_balance
      end
    end
  end
end
