module Travis::API::V3
  class Permissions::Subscription < Permissions::Generic
    def read?
      return object.permissions.read? if object.owner.is_a?(Travis::API::V3::Models::User)

      authorizer.for_org(object.owner.id, 'account_billing_view')
    rescue AuthorizerError
      object.permissions.read?
    end

    def write?
      return object.permissions.write? if object.owner.is_a?(Travis::API::V3::Models::User)

      authorizer.for_org(object.owner.id, 'account_billing_update')
    rescue AuthorizerError
      object.permissions.write?
    end
  end
end
