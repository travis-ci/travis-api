class Settings
  include ActiveModel::Model

  BINARY = %w[builds_only_with_travis_yml build_pushes build_pull_requests]
  INTEGER = %w[maximum_number_of_builds]

  attr_reader :attributes

  def initialize(settings)
    settings.each do |setting_name, setting_value|
      settings[setting_name] = set_value(setting_name, setting_value)
    end

    @attributes = defaults.merge(settings).each do |setting_name, setting_value|
      self.class.send(:attr_accessor, setting_name)
      instance_variable_set("@#{setting_name}", set_value(setting_name, setting_value))
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

  private

  def set_value(setting_name, setting_value)
    if BINARY.include?(setting_name)
      case setting_value
      when true, "1", 1  then true
      when false, "0", 0 then false
      else nil
      end
    elsif INTEGER.include?(setting_name)
      setting_value.to_i
    else
      setting_value
    end
  end
end
