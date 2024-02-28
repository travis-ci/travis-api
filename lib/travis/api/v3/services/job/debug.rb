module Travis::API::V3
  class Services::Job::Debug < Service
    params "quiet"

    attr_reader :job

    def run
      if ActiveRecord::Base.respond_to?(:yaml_column_permitted_classes)
        ActiveRecord::Base.yaml_column_permitted_classes |= [Symbol]
      end

      @job = check_login_and_find(:job)
      raise WrongCredentials unless job.repository.debug_tools_enabled?

      access_control.permissions(job).debug!
      return repo_migrated if migrated?(job.repository)

      job.debug_options = debug_data
      job.save!

      Travis::API::V3::Models::Audit.create!(owner: access_control.user, change_source: 'travis-api', source: job.repository, source_changes: { debug: 'Debug build triggered' })

      result = query.restart(access_control.user)
      if result.success?
        accepted(job: job, state_change: :created)
      else
        insufficient_balance
      end
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
