module Travis::API::V3
  class Models::Preferences < Models::JsonSlice
    child Models::Preference

    attribute :build_emails, Boolean, default: true

    # whether to show insights about the user's private repositories to
    # everybody or keep them only for the user (note: insights about public
    # repositories are always public)
    attribute :private_insights_visibility, String, default: 'private'
    validates :private_insights_visibility, inclusion: %w{private public}
  end
end
