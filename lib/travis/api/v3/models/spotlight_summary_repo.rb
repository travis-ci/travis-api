module Travis::API::V3
  class Models::SpotlightSummaryRepo
    attr_reader :repo_id, :repo_name

    def initialize(attributes = {})
      @repo_id = attributes.fetch('repo_id')
      @repo_name = attributes.fetch('repo_name')
    end
  end
end
