require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::AccountEnvVar < Permissions::Generic
    def write?
      object.owner_type == 'Organization' ?
        authorizer.for_account(object.owner_id, 'account_settings_create') :
        true
    end

    def delete?
      object.owner_type == 'Organization' ?
        authorizer.for_account(object.owner_id, 'account_settings_delete') :
        true
    end

    private

    def organization_permissions
      @organization_permissions ||= Permissions::Organization.new(access_control, {id: object.owner_id})
    end
  end
end
