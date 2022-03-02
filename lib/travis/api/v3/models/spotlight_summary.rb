module Travis::API::V3
  class Models::SpotlightSummary
    attr_reader :id, :user_id, :repo_id, :build_status, :repo_name, :builds, :duration, :credits, :license_credits, :time

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @user_id = attributes.fetch('user_id')
      @repo_id = attributes.fetch('repo_id')
      @build_status = attributes.fetch('build_status')
      @repo_name = attributes.fetch('repo_name')
      @builds = attributes.fetch('builds')
      @duration = attributes.fetch('duration')
      @credits = attributes.fetch('credits')
      @license_credits = attributes.fetch('license_credits')
      @time = attributes.fetch('time')
    end
  end
end
