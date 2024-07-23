require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Organization < Permissions::Generic
    def sync?
      return write? if Travis.config.legacy_roles

      authorizer.has_org_role?(object.id, 'account_admin')
    end

    def settings_delete?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_settings_delete')
    end

    def settings_create?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_settings_create')
    end

    def plan_invoices?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_plan_invoices')
    end

    def plan_usage?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_plan_usage')
    end

    def plan_view?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_plan_view')
    end

    def plan_create?
      return adminable? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_plan_create')
    end

    def billing_update?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_billing_update')
    end

    def billing_view?
      return write? if Travis.config.legacy_roles

      authorizer.for_org(object.id, 'account_billing_view')
    end

    def admin?
      return adminable? if Travis.config.legacy_roles

      authorizer.has_org_role?(object.id, 'account_admin')
    end

  end
end
