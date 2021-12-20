require 'travis/api/v3/models/preference'

module Travis::API::V3
  class Models::UserPreferences < Models::JsonSlice
    child Models::Preference

    attribute :build_emails, Boolean, default: true

    attribute :consume_oss_credits, Boolean, default: true

    # whether to show insights about the user's private repositories to
    # everybody or keep them only for the user (note: insights about public
    # repositories are always public)
    attribute :private_insights_visibility, String, default: 'private'
    validates :private_insights_visibility, inclusion: { in: %w{private public}, message: "'%{value}' is not allowed" }

    attribute :insights_scan_notifications, Boolean, default: true

    attribute :insights_time_zone, String, default: ''

    attribute :insights_date_format, String, default: 'DD/MM/YYYY'
    validates :insights_date_format, inclusion: { in: %w{DD/MM/YYYY MM/DD/YYYY YYYY/MM/DD}, message: "'%{value}' is not allowed" }

    attribute :insights_time_format, String, default: 'HH:mm:ss'
    validates :insights_time_format, inclusion: { in: ['h:mm:ss A', 'HH:mm:ss'], message: "'%{value}' is not allowed" }
  end
end
