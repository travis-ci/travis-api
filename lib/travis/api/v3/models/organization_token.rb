module Travis::API::V3
  class Models::OrganizationToken < Model
    belongs_to :organization
    has_many :organization_token_permissions

    serialize :token, Travis::Model::EncryptedColumn.new
  end
end
