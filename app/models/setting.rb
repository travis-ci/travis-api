class Setting
  include ActiveModel::Model

  BINARY = %w[builds_only_with_travis_yml build_pushes build_pull_requests]
  INTEGER = %w[maximum_number_of_builds]
  PERMITTED = BINARY.concat(INTEGER)

  def initialize(repository)
    defaults.merge(repository.settings).each do |setting_name, setting_value|
      self.class.send(:attr_accessor, setting_name)
      instance_variable_set("@#{setting_name}", setting_value)
    end
  end

  def defaults
    {
      "builds_only_with_travis_yml" => false,
      "build_pushes" => true,
      "build_pull_requests" => true,
      "maximum_number_of_builds" => 0
    }
  end
end
