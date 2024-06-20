module Travis::API::V3
  class Services::Log::Find < Service
    params 'log.token'

    def run!
      job = Models::Job.find(params['job.id'])

      log = query.find(job)
      repo_can_write = false
      if access_control.is_a?(Travis::API::V3::AccessControl::LogToken)
        repo_can_write = access_control.repo_can_write
      elsif access_control.user
        repo_can_write = !!job.repository.users.where(id: access_control.user.id, permissions: { push: true }).first
        raise LogAccessDenied if !Travis.config.legacy_roles && !access_control.permissions(job).view_log? && job.repository.private?
      end

      raise(NotFound, :log) unless access_control.visible? log
      raise LogExpired if !job.repository.user_settings.job_log_time_based_limit && job.started_at && job.started_at < Time.now - job.repository.user_settings.job_log_access_older_than_days.days
      raise LogAccessDenied if job.repository.user_settings.job_log_access_based_limit && (!repo_can_write || !access_control.permissions(job).view_log?)

      result log
    end
  end
end
