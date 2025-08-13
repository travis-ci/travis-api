module Travis::API::V3
  class Services::LogParts::Find < Service
    params :after, :part_numbers, :content, :require_all

    def run!
      job = Models::Job.find(params['job.id'])
      log = query.parts(job, params)
      repo_can_write = false
      if access_control.is_a?(Travis::API::V3::AccessControl::LogToken)
        repo_can_write = access_control.repo_can_write
      elsif access_control.user
        repo_can_write = !!job.repository.users.where(id: access_control.user.id, permissions: { push: true }).first
        raise LogAccessDenied if !Travis.config.legacy_roles &&
                                 !access_control.permissions(job).view_log? && job.repository.private?
      end

      raise LogExpired if expired?(job)
      raise LogAccessDenied if job.repository.user_settings.job_log_access_based_limit &&
                               (!repo_can_write || !access_control.permissions(job).view_log?)

      result log
    end

    def expired?(job)
      !job.repository.user_settings.job_log_time_based_limit &&
        job.started_at &&
        job.started_at < Time.now - job.repository.user_settings.job_log_access_older_than_days.days
    end
  end
end
