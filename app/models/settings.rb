class Settings
  include ActiveModel::Model
  include ActiveModel::Validations

  validates_inclusion_of :api_build_rate_limit, in: 0..200, message: "API builds rate limit can't execeed 200"

  BINARY = %w[auto_cancel_pushes auto_cancel_pull_requests builds_only_with_travis_yml build_pushes build_pull_requests share_encrypted_env_with_forks share_ssh_keys_with_forks job_log_time_based_limit job_log_access_based_limit]
  INTEGER = %w[maximum_number_of_builds timeout_hard_limit timeout_log_silence api_build_rate_limit job_log_access_older_than_days]

  attr_reader :attributes

  def initialize(settings)
    if settings.is_a? String
      settings = YAML.load(settings)
    end
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
      "maximum_number_of_builds" => 0,
      "auto_cancel_pushes" => false,
      "auto_cancel_pull_requests" => false,
      "share_encrypted_env_with_forks" => false,
      "share_ssh_keys_with_forks" => true,
      "timeout_hard_limit" => 0,
      "timeout_log_silence" => 0,
      "api_build_rate_limit" => 0
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
