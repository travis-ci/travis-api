module Travis::API::V3
  class Models::User < Model
    has_many :memberships,   dependent: :destroy
    has_many :permissions,   dependent: :destroy
    has_many :emails,        dependent: :destroy
    has_many :tokens,        dependent: :destroy
    has_many :repositories,  through:   :permissions
    has_many :organizations, through:   :memberships


    serialize :github_oauth_token, Extensions::EncryptedColumn.new(disable: true)

    def token
      tokens.first_or_create.token
    end
  end
end
