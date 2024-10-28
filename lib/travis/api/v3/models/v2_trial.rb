module Travis::API::V3
  class Models::V2Trial

    attr_reader :concurrency_limit, :max_builds, :max_jobs_per_build, :status, :builds_triggered, :started_at, :finish_time, :credit_usage, :user_usage

    def initialize(attributes = {})
      @concurrency_limit = attributes.fetch('concurrency_limit')
      @max_builds = attributes.fetch('max_builds')
      @max_jobs_per_build = attributes.fetch('max_jobs_per_build')
      @builds_triggered = attributes.fetch('builds_triggered')
      @status = attributes.fetch('status')
      @started_at = attributes.fetch('started_at')
      @finish_time = attributes.fetch('finish_time')
      c_usage =  attributes.fetch('credit_usage', nil)
      @credit_usage = Models::V2AddonUsage.new(c_usage) if c_usage
      u_usage = attributes.fetch('user_usage', nil)
      @user_usage = Models::V2AddonUsage.new(u_usage) if u_usage
    end
  end
end
