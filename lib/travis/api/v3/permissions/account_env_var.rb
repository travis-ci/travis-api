require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::AccountEnvVar < Permissions::Generic
    def write?
      authorizer.for_account(object.owner_id, 'account_settings_create') if object.owner_type == 'Organization'
    end

    def delete?
      Travis.logger.info "checking rights"
      Travis.logger.info "the object: #{object.owner_id}"
      return authorizer.for_account(object.owner_id, 'account_settings_delete') if object.owner_type == 'Organization'
      Travis.logger.info "user rights"
    end

    private

    def organization_permissions
      @organization_permissions ||= Permissions::Organization.new(access_control, {id: object.owner_id})
    end
  end
end
