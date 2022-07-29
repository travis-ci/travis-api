module Travis::API::V3
  class Services::Log::Find < Service
    params 'log.token'

    def run!
      job = Models::Job.find(params['job.id'])
      repo_can_write = access_control.user ? !!job.repository.users.where(id: access_control.user.id, permissions: { push: true }).first : false

      log = query.find(job)
      raise(NotFound, :log) unless access_control.visible? log
      raise LogExpired if job.repository.user_settings.job_log_time_based_limit && job.started_at < Time.now - job.repository.user_settings.job_log_access_older_than_days.days
      raise LogAccessDenied if job.repository.user_settings.job_log_access_based_limit && !repo_can_write

      result log
    end
  end
end
