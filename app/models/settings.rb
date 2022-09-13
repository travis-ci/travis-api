class Settings
  include ActiveModel::Model
  include ActiveModel::Validations

  validates_inclusion_of :api_build_rate_limit, in: 0..200, message: "API builds rate limit can't execeed 200"

  FIELDS = {
    :auto_cancel_pushes => {
      :type => :BINARY
    },
    :auto_cancel_pull_requests => {
      :type => :BINARY
    },
    :builds_only_with_travis_yml => {
      :type => :BINARY
    },
    :build_pushes => {
      :type => :BINARY
    },
    :build_pull_requests => {
      :type => :BINARY
    },
    :share_encrypted_env_with_forks => {
      :type => :BINARY
    },
    :share_ssh_keys_with_forks => {
      :type => :BINARY
    },
    :job_log_time_based_limit => {
      :type => :BINARY,
      :description => 'Enable access via API/UI to build logs older than'
    },
    :job_log_access_older_than_days => {
      :type => :INTEGER,
      :description => 'days (threshold after which job log is "old")'
    },
    :job_log_access_based_limit => {
      :type => :BINARY,
      :description => 'Limit access to build job logs (users with write/push access only)'
    },
    :maximum_number_of_builds => {
      :type => :INTEGER
    },
    :timeout_hard_limit => {
      :type => :INTEGER
    },
    :timeout_log_silence => {
      :type => :INTEGER
    },
    :api_build_rate_limit => {
      :type => :INTEGER
    }
  }

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
      "api_build_rate_limit" => 0,
      "job_log_time_based_limit" => false,
      "job_log_access_based_limit" => false,
      "job_log_access_older_than_days" => 365
    }
  end

  private

  def set_value(setting_name, setting_value)
    setting_symbol = setting_name.to_sym
    if FIELDS.include?(setting_symbol)
      if FIELDS[setting_symbol][:type] == :BINARY
        case setting_value
        when true, "1", 1  then true
        when false, "0", 0 then false
        else nil
        end
      elsif FIELDS[setting_symbol][:type] == :INTEGER
        setting_value.to_i
      else
        setting_value
      end
    else
      setting_value
    end
  end
end
