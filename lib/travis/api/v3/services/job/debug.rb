module Travis::API::V3
  class Services::Job::Debug < Service

    def run
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless job = find(:job)
      access_control.permissions(job).debug!

      Travis.logger.debug "Reached endpoint"
      job = service(:find_job, params).run
      Travis.logger.debug "found job: #{job}"
      cfg = job.config
      cfg.merge! debug_data
      job.save!

      accepted(job: job, state_change: :created)
    end
  end
end
