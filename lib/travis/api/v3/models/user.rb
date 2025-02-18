require 'travis/api/v3/models/user_preferences'

module Travis::API::V3
  class Models::User < Model
    has_many :memberships,   dependent: :destroy
    has_many :permissions,   dependent: :destroy
    has_many :emails,        dependent: :destroy
    has_many :tokens,        dependent: :destroy
    has_many :organizations, through:   :memberships
    has_many :stars
    has_many :email_unsubscribes
    has_many :user_beta_features
    has_many :beta_features, through: :user_beta_features
    has_many :beta_migration_requests

    has_preferences Models::UserPreferences

    after_initialize do
      ensure_preferences
    end

    before_save do
      ensure_preferences
    end

    serialize :github_oauth_token, Travis::Model::EncryptedColumn.new
    scope :with_github_token, -> { where('github_oauth_token IS NOT NULL')}

    NEW_USER_INDICATOR_LENGTH = 5

    def recently_signed_up
      # We need indicator, which tells if user is signed up for the very first time
      # is_syncing == true && synced_at == nil is not good indicator, because travis-github-sync
      # picks user's repos immediatelly.
      # If first_logged_in_at is not older than 5sec we are sure this is first call after first handshake.
      first_logged_in_at = read_attribute(:first_logged_in_at)
      return false if first_logged_in_at.nil?
      Time.now - first_logged_in_at < NEW_USER_INDICATOR_LENGTH
    end

    def repository_ids
      repositories.pluck(:id)
    end

    def repositories
      Models::Repository.where(
        '((repositories.owner_type = ? AND repositories.owner_id = ?) OR repositories.id IN (?))'.freeze,
        'User'.freeze,
        id,
        shared_repositories_ids
      ).order('id ASC')
    end

    def organizations_repositories_ids
      @organizations_repositories_ids ||= organizations.empty? ? [] : Models::Repository.where(owner_id: organizations.pluck(:id)).pluck(:id)
    end

    def access_repositories_ids
      @access_repositories_ids ||= permissions.pluck(:repository_id)
    end

    def shared_repositories_ids
      access_repositories_ids - organizations_repositories_ids
    end

    def token
      tokens.first_or_create.token
    end

    def starred_repository_ids
      @starred_repository_ids ||= stars.map(&:repository_id)
    end

    def email_unsubscribed_repository_ids
      @email_unsubscribed_repository_ids ||= email_unsubscribes.map(&:repository_id)
    end

    def permission?(roles, options = {})
      roles, options = nil, roles if roles.is_a?(Hash)
      scope = permissions.where(options)
      scope = scope.by_roles(roles) if roles
      scope.any?
    end

    def installation
      return @installation if defined? @installation
      @installation = Models::Installation.find_by(owner_type: 'User', owner_id: id, removed_by_id: nil)
    end

    def internal?
      !!get_internal_user
    end

    def get_internal_user
      Travis.config[:internal_users]&.find { |item| item[:id] == id }
    end

    def login
      read_attribute(:login) || get_internal_user&.dig(:login)
    end

    def github?
      vcs_type == 'GithubUser'
    end

    def ensure_preferences
      return if attributes['preferences'].nil?
      self.preferences = self['preferences'].is_a?(String) ? JSON.parse(self['preferences']) : self['preferences']
    end

    def custom_keys
      return @custom_keys if defined? @custom_keys
      @custom_keys = Models::CustomKey.where(owner_type: 'User', owner_id: id)
    end
  end
end
