module Travis::API::V3
  class Models::Cron < Model
    SCHEDULER_INTERVAL = 1.minute
    LOOKBACK_INTERVAL = 30.minute

    belongs_to :branch
    after_create :schedule_first_build

    scope :scheduled, -> { where("next_run <= (?) AND next_run > (?) AND active = (?)", DateTime.now.utc, LOOKBACK_INTERVAL.ago, true) }
    scope :skipped, -> { where("next_run <= '#{LOOKBACK_INTERVAL.ago}'")}

    TIME_INTERVALS = {
      "daily"   => :day,
      "weekly"  => :week,
      "monthly" => :month
    }

    REPO_IS_INACTIVE = "repo is inactive"
    BRANCH_MISSING_ON_GH = "branch doesn't exist on Github"

    def schedule_next_build
      update_attribute(:next_run, calculate_next_run)
    end

    def schedule_first_build
      update_attribute(:next_run, created_at + SCHEDULER_INTERVAL)
    end

    def needs_new_build?
      return false unless active?
      return true if always_run?
      return true unless last_non_cron_build_time
      return true if last_non_cron_build_time < 24.hour.ago
    end

    def skip_and_schedule_next_build
      last_build_time = last_non_cron_build_time
      update_attribute(:last_run, last_build_time)

      schedule_next_build
    end

    def enqueue
      return deactivate_and_log_reason(REPO_IS_INACTIVE) unless branch.repository&.active?

      return deactivate_and_log_reason(BRANCH_MISSING_ON_GH) unless branch.exists_on_github

      user_id = branch.repository.users.detect { |u| u.github_oauth_token }.try(:id)
      user_id ||= branch.repository.owner.id

      payload = {
        repository: {
          id:         branch.repository.github_id,
          owner_name: branch.repository.owner_name,
          name:       branch.repository.name },
        branch:     branch.name,
        user:       { id: user_id }
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
      update_attributes!(active: false)
    end

    def deactivate_and_log_reason(reason)
      Travis.logger.info "Removing cron #{self.id} because the associated #{reason}"
      deactivate
      false
    end

    # make sure it is always int he future
    def calculate_next_run
    end
  end
end
