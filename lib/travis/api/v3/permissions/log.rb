require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Log < Permissions::Generic
    def cancel?
      return cancelable? if Travis.config.legacy_roles

      authorizer.for_repo(object.job.repository_id, 'repository_build_cancel')
    end

    def restart?
      return restartable? if Travis.config.legacy_roles

      authorizer.for_repo(object.job.repository_id, 'repository_build_restart')
    end

    def debug?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.job.repository_id, 'repository_build_debug')
    end

    def delete_log?
      return write? if Travis.config.legacy_roles

      authorizer.for_repo(object.job.repository_id, 'repository_log_delete')
    end

    def view_log?
      return read? if Travis.config.legacy_roles

      authorizer.for_repo(object.job.repository_id, 'repository_log_view')
    end
  end
end
