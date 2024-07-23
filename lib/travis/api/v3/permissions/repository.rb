require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Repository < Permissions::Generic
    def activate?
      return write? if Travis.config.legacy_roles

      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    end

    def deactivate?
      return write? if Travis.config.legacy_roles

      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    end

    def migrate?
      return admin? && object.allow_migration? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_state_update') && object.allow_migration?
    end

    def star?
      starable?
    end

    def unstar?
      starable?
    end

    def create_cron?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_create') && authorizer.for_repo(object.id, 'repository_build_create')
    end

    def create_env_var?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def create_key_pair?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def delete_key_pair?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_delete')
    end

    def create_request?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_build_create')
    end

    def check_scan_results?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_scans_view')
    end

    def settings_create?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def settings_delete?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_delete')
    end

    def settings_update?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_update')
    end

    def settings_read?
      return read? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_settings_read')
    end

    def build_restart?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_build_restart')
    end

    def build_create?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_build_create')
    end

    def build_cancel?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_build_cancel')
    end

    def build_debug?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_build_debug')
    end

    def log_view?
      return read? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_log_view')
    end

    def log_delete?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_log_delete')
    end

    def cache_delete?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_cache_delete')
    end

    def cache_view?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.id, 'repository_cache_view')
    end

    def admin?
      return access_control.adminable? object if Travis.config.legacy_roles

      authorizer.has_repo_role?(object.id, 'repository_admin')
    end
  end
end
