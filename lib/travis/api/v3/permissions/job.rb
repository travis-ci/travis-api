require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Job < Permissions::Generic
    def cancel?
      return cancelable? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_build_cancel')
    end

    def restart?
      return restartable? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_build_restart')
    end

    def debug?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_build_debug')
    end

    def delete_log?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_log_delete')
    end

    def view_log?
      return read? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_log_view')
    end

    def prioritize?
      return read? && build_priorities? if Travis.config.legacy_roles

      authorizer.for_repo(object.repository_id, 'repository_build_create') && build_priorities?
    end
  end
end
