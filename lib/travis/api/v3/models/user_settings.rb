require 'json'

module Travis::API::V3
  class Models::UserSettings < Models::JsonSlice
    child Models::UserSetting

    attribute :builds_only_with_travis_yml, Boolean, default: false
    attribute :build_pushes, Boolean, default: true
    attribute :build_pull_requests, Boolean, default: true
    attribute :build_releases, Boolean, default: true
    attribute :maximum_number_of_builds, Integer, default: 0
    attribute :auto_cancel_pushes, Boolean, default: lambda { |us, _| us.auto_cancel_default? }
    attribute :auto_cancel_pull_requests, Boolean, default: lambda { |us, _| us.auto_cancel_default? }
    attribute :allow_config_imports, Boolean, default: false
    attribute :config_validation, Boolean, default: lambda { |us, _| us.config_validation? }
    attribute :share_encrypted_env_with_forks, Boolean, default: false
    attribute :share_ssh_keys_with_forks, Boolean, default: lambda { |us, _| us.share_ssh_keys_with_forks? }
    attribute :job_log_time_based_limit, Boolean, default: lambda { |s, _| s.job_log_access_permissions[:time_based_limit] }
    attribute :job_log_access_based_limit, Boolean, default: lambda { |s, _| s.job_log_access_permissions[:access_based_limit] }
    attribute :job_log_access_older_than_days, Integer, default: lambda { |s, _| s.job_log_access_permissions[:older_than_days] }

    validates :job_log_access_older_than_days, numericality: true

    validate :job_log_access_older_than_days_restriction

    set_callback :after_save, :after, :save_audit

    attr_reader :repo

    attr_accessor :user, :change_source

    def initialize(repo, data)
      @repo = repo
      super(data)
    end

    def repository_id
      repo && repo.id
    end

    def auto_cancel_default?
      ENV.fetch('AUTO_CANCEL_DEFAULT', 'false') == 'true'
    end

    NOV_15 = Date.parse('2019-11-15')
    JAN_15 = Date.parse('2020-01-15')

    def config_validation?
      return false if ENV['RACK_ENV'] == 'test'
      new_repo? || old_repo?
    end

    def share_ssh_keys_with_forks?
      return false unless ENV['IBM_REPO_SWITCHES_DATE']

      repo.created_at <= Date.parse(ENV['IBM_REPO_SWITCHES_DATE'])
    end

    def new_repo?
      repo.created_at >= NOV_15
    end

    def old_repo?
      Date.today >= JAN_15 && repo.created_at >= cutoff_date
    end

    def cutoff_date
       NOV_15 - days_since_jan_15 * 30 * 2 # i.e. we roll back by ~2 months per day
    end

    def days_since_jan_15
      Date.today.mjd - JAN_15.mjd + 1
    end

    def job_log_access_permissions
      Travis.config.to_h.fetch(:job_log_access_permissions) { {} }
    end

    def job_log_access_older_than_days_restriction
      if job_log_access_older_than_days.to_i > job_log_access_permissions[:max_days_value] ||
        job_log_access_older_than_days.to_i < job_log_access_permissions[:min_days_value]
        errors.add(:job_log_access_older_than_days, "is outside the bounds")
      end
    end

    private

    def save_audit
      if self.change_source
        Travis::API::V3::Models::Audit.create!(owner: self.user, change_source: self.change_source, source: self.repo, source_changes: { settings: self.changes })
      end
    end
  end
end
