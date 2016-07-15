module Travis::API::V3
  class Services::Job::Debug < Service
    params "quiet"

    attr_reader :job

    def run
      @job = check_login_and_find(:job)
      raise WrongCredentials unless Travis.config.debug_tools_enabled or Travis::Features.active?(:debug_tools, job.repository)
      access_control.permissions(job).debug!

      job.debug_options = debug_data
      job.save!

      query.restart(access_control.user)
      accepted(job: job, state_change: :created)
    end

    def debug_data
      {
        stage: 'before_install',
        previous_state: job.state,
        created_by: access_control.user.login,
        quiet: params["quiet"] || false
      }
    end
  end
end
