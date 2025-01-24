module Travis::API::V3
  class Permissions::AccountEnvVar < Permissions::Generic
    def write?
      return organization_permissions.admin? if object.owner_type == 'Organization'
      authorizer.for_account(object.owner_id, 'account_settings_create')
    end

    def delete?
      return organization_permissions.admin? if object.owner_type == 'Organization'
      authorizer.for_account(object.owner_id, 'account_settings_delete')
    end

    private

    def organization_permissions
      @organization_permissions ||= Permissions::Organization.new(access_control, {id: object.owner_id})
    end
  end
end
