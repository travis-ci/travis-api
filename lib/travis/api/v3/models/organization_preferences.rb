require 'travis/api/v3/models/preference'

module Travis::API::V3
  class Models::OrganizationPreferences < Models::JsonSlice
    child Models::Preference

    attribute :public_insights, Boolean, default: false
    attribute :members_insights, Boolean, default: false
  end
end
