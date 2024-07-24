module Travis::API::V3
  class Permissions::Subscription < Permissions::Generic
    def read?
      return object.permissions.read? if Travis.config.legacy_roles || object.owner.is_a?(Travis::API::V3::Models::User)

      authorizer.for_org(object.owner.id, 'account_billing_view')
    end

    def write?
      return object.permissions.write? if Travis.config.legacy_roles || object.owner.is_a?(Travis::API::V3::Models::User)

      authorizer.for_org(object.owner.id, 'account_billing_update')
    end
  end
end
