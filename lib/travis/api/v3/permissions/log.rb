require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Log < Permissions::Generic
    def cancel?
      authorizer.for_repo(object.job.repository_id, 'repository_build_cancel')
    end

    def restart?
      authorizer.for_repo(object.job.repository_id, 'repository_build_restart')
    end

    def debug?
      authorizer.for_repo(object.job.repository_id, 'repository_build_debug')
    end

    def delete_log?
      authorizer.for_repo(object.job.repository_id, 'repository_log_delete')
    end

    def view_log?
      authorizer.for_repo(object.job.repository_id, 'repository_log_view')
    end
  end
end
