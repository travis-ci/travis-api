require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Organization < Permissions::Generic
    def sync?
      authorizer.has_org_role?(object.id, 'account_admin')
    rescue AuthorizerError
      write?
    end

    def settings_delete?
      authorizer.for_org(object.id, 'account_settings_delete')
    rescue AuthorizerError
      write?
    end

    def settings_create?
      authorizer.for_org(object.id, 'account_settings_create')
    rescue AuthorizerError
      write?
    end

    def plan_invoices?
      authorizer.for_org(object.id, 'account_plan_invoices')
    rescue AuthorizerError
      write?
    end

    def plan_usage?
      authorizer.for_org(object.id, 'account_plan_usage')
    rescue AuthorizerError
      write?
    end

    def plan_view?
      authorizer.for_org(object.id, 'account_plan_view')
    rescue AuthorizerError
      write?
    end

    def plan_create?
      authorizer.for_org(object.id, 'account_plan_create')
    rescue AuthorizerError
      adminable?
    end

    def billing_update?
      authorizer.for_org(object.id, 'account_billing_update')
    rescue AuthorizerError
      adminable?
    end

    def billing_view?
      authorizer.for_org(object.id, 'account_billing_view')
    rescue AuthorizerError
      write?
    end

    def admin?
      authorizer.has_org_role?(object.id, 'account_admin')
    rescue AuthorizerError
      adminable?
    end

  end
end
