require 'travis/api/v3/models/organization_preferences'

module Travis::API::V3
  class Models::Organization < Model
    default_scope { where(deleted_at: nil) }
    has_many :memberships
    has_many :users, through: :memberships
    has_one  :beta_migration_request
    has_many :account_env_vars, as: :owner

    has_preferences Models::OrganizationPreferences

    scope :by_login, ->(login, provider) { where(
      'lower(login) = ? and lower(vcs_type) = ?'.freeze,
      login.downcase,
      provider.downcase + 'organization'
    ).order("id DESC") }

    after_initialize do
      ensure_preferences
    end

    before_save do
      ensure_preferences
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

    def builds
      Models::Build.where(owner_type: 'Organization', owner_id: id)
    end

    def build_priorities_enabled?
      Travis::Features.owner_active?(:build_priorities_org, self)
    end

    def ensure_preferences
      return if attributes['preferences'].nil?
      self.preferences = self['preferences'].is_a?(String) ? JSON.parse(self['preferences']) : self['preferences']
    end

    def custom_keys
      @custom_keys ||= Models::CustomKey.where(owner_type: 'Organization', owner_id: id)
    end

    def account_env_vars
      @account_env_vars ||= Models::AccountEnvVar.where(owner_type: 'Organization', owner_id: id)
    end

    alias members users
  end
end
