module Travis::API::V3
  class Permissions::Trial < Permissions::Generic
    def read?
      authorizer.for_org(object.id, 'account_billing_view')
    rescue AuthorizerError
      object.permissions.read?
    end

    def write?
      authorizer.for_org(object.id, 'account_billing_update')
    rescue AuthorizerError
      object.permissions.write?
    end
  end
end
