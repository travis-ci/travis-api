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

    has_preferences Models::UserPreferences

    serialize :github_oauth_token, Travis::Model::EncryptedColumn.new
    scope :with_github_token, -> { where('github_oauth_token IS NOT NULL')}

    def repository_ids
      repositories.pluck(:id)
    end

    def repositories
      Models::Repository.where(owner_type: 'User', owner_id: id)
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
  end
end
