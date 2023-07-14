require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Repository < Permissions::Generic
    def activate?
      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    end

    def deactivate?
      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    end

    def migrate?
      authorizer.for_repo(object.id, 'repository_state_update') && object.allow_migration?
    end

    def star?
      starable?
    end

    def unstar?
      starable?
    end

    def create_cron?
      authorizer.for_repo(object.id, 'repository_settings_create') && authorizer.for_repo(object.id, 'repository_build_create')
    end

    def create_env_var?
      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def create_key_pair?
      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def delete_key_pair?
      authorizer.for_repo(object.id, 'repository_settings_delete')
    end

    def create_request?
      authorizer.for_repo(object.id, 'repository_build_create')
    end

    def check_scan_results?
      authorizer.for_repo(object.id, 'repository_scans_view')
    end

    def settings_create?
      authorizer.for_repo(object.id, 'repository_settings_create')
    end

    def settings_delete?
      authorizer.for_repo(object.id, 'repository_settings_delete')
    end

    def settings_update?
      authorizer.for_repo(object.id, 'repository_settings_update')
    end

    def settings_read?
      authorizer.for_repo(object.id, 'repository_settings_read')
    end

    def build_restart?
      authorizer.for_repo(object.id, 'repository_build_restart')
    end

    def build_create?
      authorizer.for_repo(object.id, 'repository_build_create')
    end

    def build_cancel?
      authorizer.for_repo(object.id, 'repository_build_cancel')
    end

    def build_debug?
      authorizer.for_repo(object.id, 'repository_build_debug')
    end

    def log_view?
      authorizer.for_repo(object.id, 'repository_log_view')
    end

    def log_delete?
      authorizer.for_repo(object.id, 'repository_log_delete')
    end

    def cache_delete?
      authorizer.for_repo(object.id, 'repository_cache_delete')
    end

    def cache_view?
      authorizer.for_repo(object.id, 'repository_cache_view')
    end

    def admin?
      authorizer.has_repo_role?(object.id, 'repository_admin')
    end
  end
end
