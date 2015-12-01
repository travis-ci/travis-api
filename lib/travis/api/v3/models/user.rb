module Travis::API::V3
  class Models::User < Model
    has_many :memberships,   dependent: :destroy
    has_many :permissions,   dependent: :destroy
    has_many :emails,        dependent: :destroy
    has_many :tokens,        dependent: :destroy
    has_many :organizations, through:   :memberships
    has_many :repositories,  as:        :owner
    has_many :stars
    has_one  :subscription,  as:        :owner

    serialize :github_oauth_token, Extensions::EncryptedColumn.new(disable: true)

    def token
      tokens.first_or_create.token
    end

    def subscription
      super if Features.use_subscriptions?
    end

    def starred_repository_ids
      @starred_repository_ids ||= stars.map(&:repository_id)
    end
  end
end
