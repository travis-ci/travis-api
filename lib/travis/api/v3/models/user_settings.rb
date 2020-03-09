module Travis::API::V3
  class Models::UserSettings < Models::JsonSlice
    child Models::UserSetting

    attribute :builds_only_with_travis_yml, Boolean, default: false
    attribute :build_pushes, Boolean, default: true
    attribute :build_pull_requests, Boolean, default: true
    attribute :maximum_number_of_builds, Integer, default: 0
    attribute :auto_cancel_pushes, Boolean, default: lambda { |us, _| us.auto_cancel_default? }
    attribute :auto_cancel_pull_requests, Boolean, default: lambda { |us, _| us.auto_cancel_default? }
    attribute :allow_config_imports, Boolean, default: false
    attribute :config_validation, Boolean, default: lambda { |us, _| us.config_validation? }

    attr_reader :repo

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
  end
end
