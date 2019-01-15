module Travis::API::V3
  class Models::Preferences < Models::JsonSlice
    child Models::Preference

    attribute :build_emails, Boolean, default: true
  end
end
