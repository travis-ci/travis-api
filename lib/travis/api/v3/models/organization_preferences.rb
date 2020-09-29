require 'travis/api/v3/models/preference'

module Travis::API::V3
  class Models::OrganizationPreferences < Models::JsonSlice
    child Models::Preference

    attribute :consume_oss_credits, Boolean, default: true

    # whether to show insights about the organization's private repositories to
    # only admins, all members of the organization, or everybody (public) (note:
    # insights about public repositories are always public)
    attribute :private_insights_visibility, String, default: 'admins'
    validates :private_insights_visibility, inclusion: { in: %w{admins members public}, message: "'%{value}' is not allowed" }
  end
end
