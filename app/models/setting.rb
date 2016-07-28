class Setting
  include ActiveModel::Model

  BINARY = %w[builds_only_with_travis_yml build_pushes build_pull_requests]
  INTEGER = %w[maximum_number_of_builds]

  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def defaults
    {
      "builds_only_with_travis_yml" => false,
      "build_pushes" => true,
      "build_pull_requests" => true,
      "maximum_number_of_builds" => 0
    }
  end

  def get
    defaults.merge(@repository.settings)
  end
end
