module Travis::API::V3
  class Services::Job::Debug < Service
    params "quiet"

    def run
      raise LoginRequired unless access_control.logged_in? or access_control.full_access?
      raise NotFound      unless job = find(:job)
      access_control.permissions(job).debug!

      job.config.merge! debug_data
      job.save!

      query.restart(access_control.user)
      accepted(job: job, state_change: :created)
    end

    def debug_data(j)
      {
        debug: {
          stage: 'before_install',
          previous_state: j.state,
          created_by: access_control.user.login,
          quiet: params["quiet"] || false
        }
      }
    end
  end
end
