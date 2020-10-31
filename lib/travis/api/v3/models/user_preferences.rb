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
  end
end
