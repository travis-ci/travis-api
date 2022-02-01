module Travis::API::V3
  class Models::InsightsSpotlightSummary
    attr_reader :id, :user_id, :repo_id, :build_status, :repo_name, :builds, :minutes, :credits, :time

    def initialize(attributes = {})
      @id = attributes.fetch('id')
      @user_id = attributes.fetch('user_id')
      @repo_id = attributes.fetch('repo_id')
      @build_status = attributes.fetch('build_status')
      @repo_name = attributes.fetch('repo_name')
      @builds = attributes.fetch('builds')
      @minutes = attributes.fetch('minutes')
      @credits = attributes.fetch('credits')
      @time = attributes.fetch('time')
    end
  end
end
