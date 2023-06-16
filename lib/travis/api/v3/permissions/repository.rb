require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Repository < Permissions::Generic
    def activate?
      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    rescue AuthorizerError
      write?
    end

    def deactivate?
      notgit_allowance = object.server_type == nil || object.server_type == 'git' || admin?
      authorizer.for_repo(object.id, 'repository_state_update') && notgit_allowance
    rescue AuthorizerError
      write?
    end

    def migrate?
      authorizer.for_repo(object.id, 'repository_state_update') && object.allow_migration?
    rescue AuthorizerError
      admin? && object.allow_migration?
    end

    def star?
      starable?
    end

    def unstar?
      starable?
    end

    def create_cron?
      authorizer.for_repo(object.id, 'repository_settings_create') && authorizer.for_repo(object.id, 'repository_build_create')
    rescue AuthorizerError
      write?
    end

    def create_env_var?
      authorizer.for_repo(object.id, 'repository_settings_create')
    rescue AuthorizerError
      write?
    end

    def create_key_pair?
      authorizer.for_repo(object.id, 'repository_settings_create')
    rescue AuthorizerError
      write?
    end

    def delete_key_pair?
      authorizer.for_repo(object.id, 'repository_settings_delete')
    rescue AuthorizerError
      write?
    end

    def create_request?
      authorizer.for_repo(object.id, 'repository_build_create')
    rescue AuthorizerError
      write?
    end

    def check_scan_results?
      authorizer.for_repo(object.id, 'repository_scans_view')
    rescue AuthorizerError
      write?
    end

    def settings_create?
      authorizer.for_repo(object.id, 'repository_settings_create')
    rescue AuthorizerError
      write?
    end

    def settings_delete?
      authorizer.for_repo(object.id, 'repository_settings_delete')
    rescue AuthorizerError
      write?
    end

    def settings_update?
      authorizer.for_repo(object.id, 'repository_settings_update')
    rescue AuthorizerError
      write?
    end

    def settings_read?
      authorizer.for_repo(object.id, 'repository_settings_read')
    rescue AuthorizerError
      read?
    end

    def build_restart?
      authorizer.for_repo(object.id, 'repository_build_restart')
    rescue AuthorizerError
      write?
    end

    def build_create?
      authorizer.for_repo(object.id, 'repository_build_create')
    rescue AuthorizerError
      write?
    end

    def build_cancel?
      authorizer.for_repo(object.id, 'repository_build_cancel')
    rescue AuthorizerError
      write?
    end

    def build_debug?
      authorizer.for_repo(object.id, 'repository_build_debug')
    rescue AuthorizerError
      write?
    end

    def log_view?
      authorizer.for_repo(object.id, 'repository_log_view')
    rescue AuthorizerError
      read?
    end

    def log_delete?
      authorizer.for_repo(object.id, 'repository_log_delete')
    rescue AuthorizerError
      write?
    end

    def cache_delete?
      authorizer.for_repo(object.id, 'repository_cache_delete')
    rescue AuthorizerError
      write?
    end

    def cache_view?
      authorizer.for_repo(object.id, 'repository_cache_view')
    rescue AuthorizerError
      write?
    end

    def admin?
      authorizer.has_repo_role?(object.id, 'repository_admin')
    rescue AuthorizerError
      access_control.adminable? object
    end
  end
end
