require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Organization < Permissions::Generic
    def sync?
      authorizer.has_org_role?(object.id, 'account_admin')
    end

    def settings_delete?
      authorizer.for_org(object.id, 'account_settings_delete')
    end

    def settings_create?
      authorizer.for_org(object.id, 'account_settings_create')
    end

    def plan_invoices?
      authorizer.for_org(object.id, 'account_plan_invoices')
    end

    def plan_usage?
      authorizer.for_org(object.id, 'account_plan_usage')
    end

    def plan_view?
      authorizer.for_org(object.id, 'account_plan_view')
    end

    def plan_create?
      authorizer.for_org(object.id, 'account_plan_create')
    end

    def billing_update?
      authorizer.for_org(object.id, 'account_billing_update')
    end

    def billing_view?
      authorizer.for_org(object.id, 'account_billing_view')
    end

    def admin?
      authorizer.has_org_role?(object.id, 'account_admin')
    end

  end
end
