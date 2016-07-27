class Setting
  include ActiveModel::Model

  BINARY = %w[builds_only_with_travis_yml build_pushes build_pull_requests]
  INTEGER = %w[maximum_number_of_builds timeout_hard_limit timeout_log_silence api_builds_rate_limit]

  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def get
    @repository.settings || {}
  end
end
