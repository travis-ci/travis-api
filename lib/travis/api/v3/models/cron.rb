module Travis::API::V3
  class Models::Cron < Model
    SCHEDULER_INTERVAL = 1.minute

    belongs_to :branch
    after_create :schedule_first_build

    scope :scheduled, -> { where("next_run <= (?) AND active = (?)", DateTime.now.utc, true) }

    TIME_INTERVALS = {
      "daily"   => :day,
      "weekly"  => :week,
      "monthly" => :month
    }

    REPO_IS_INACTIVE = "repo is inactive"
    BRANCH_MISSING_ON_GH = "branch doesn't exist on Github"

    def schedule_next_build(from: nil)
      # Make sure the next build will always be in the future
      if (from && (from <= (DateTime.now.utc - 1.send(TIME_INTERVALS[interval]))))
        from = DateTime.now.utc
      end

      update_attribute(:next_run, (from || last_run || DateTime.now.utc) + 1.send(TIME_INTERVALS[interval]))
    end

    def schedule_first_build
      update_attribute(:next_run, DateTime.now.utc + SCHEDULER_INTERVAL)
    end

    def needs_new_build?
      return false unless active?
      return true if always_run?
      return true unless last_non_cron_build_time
      return true if last_non_cron_build_time < 24.hour.ago
    end

    def skip_and_schedule_next_build
      # Update last_run also, because this build wasn't enqueued through Queries::Crons
      last_build_time = last_non_cron_build_time
      update_attribute(:last_run, last_build_time)

      schedule_next_build(from: DateTime.now)
    end

    def enqueue
      return deactivate_and_log_reason(REPO_IS_INACTIVE) unless branch.repository&.active?

      return deactivate_and_log_reason(BRANCH_MISSING_ON_GH) unless branch.exists_on_github

      payload = {
        repository: {
          id:         branch.repository.vcs_id || branch.repository.github_id,
          vcs_type:   branch.repository.vcs_type,
          owner_name: branch.repository.owner_name,
          name:       branch.repository.name },
        branch:     branch.name,
        user:       { id: 0 }
      }

      ::Travis::API::Sidekiq.gatekeeper(
        type:        'cron'.freeze,
        payload:     JSON.dump(payload),
        credentials: {}
      )

      update_attribute(:last_run, DateTime.now.utc)
      schedule_next_build
    end

    private
    def always_run?
      !dont_run_if_recent_build_exists
    end

    def last_non_cron_build_time
      Build.find_by_id(branch.last_build_id)&.started_at&.to_datetime&.utc
    end

    def deactivate
      update!(active: false)
    end

    def deactivate_and_log_reason(reason)
      Travis.logger.info "Removing cron #{self.id} because the associated #{reason}"
      deactivate
      false
    end
  end
end
