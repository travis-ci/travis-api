module Travis::API::V3
  class Models::OrganizationTokenPermission < Model
    belongs_to :organization_token
  end
end
