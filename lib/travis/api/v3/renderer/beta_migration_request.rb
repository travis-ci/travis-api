module Travis::API::V3
  class Renderer::BetaMigrationRequest < ModelRenderer
    representation(:standard, :id, :owner_id, :owner_name, :owner_type, :accepted_at, :organizations, :organizations_logins)

    def organizations
      model.organizations.map(&:id)
    end

    def organizations_logins
      model.organizations.map(&:login)
    end
  end
end
