require 'travis/api/v3/models/organization_preferences'

module Travis::API::V3
  class Models::Organization < Model
    has_many :memberships
    has_many :users, through: :memberships
    has_one  :beta_migration_request

    has_preferences Models::OrganizationPreferences

    def vcs_id
      read_attribute(:vcs_id) || github_id
    end

    def repositories
      Models::Repository.where(owner_type: 'Organization', owner_id: id)
    end

    def installation
      return @installation if defined? @installation
      @installation = Models::Installation.find_by(owner_type: 'Organization', owner_id: id, removed_by_id: nil)
    end

    def education
      Travis::Features.owner_active?(:educational_org, self)
    end

    alias members users
  end
end
