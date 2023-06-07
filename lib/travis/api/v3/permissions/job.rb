require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Job < Permissions::Generic
    def cancel?
      authorizer.for_repo(object.id, 'repository_build_cancel')
    rescue AuthorizerError
      cancelable?
    end

    def restart?
      authorizer.for_repo(object.id, 'repository_build_restart')
    rescue AuthorizerError
      restartable?
    end

    def debug?
      authorizer.for_repo(object.id, 'repository_build_debug')
    rescue AuthorizerError
      write?
    end

    def delete_log?
      authorizer.for_repo(object.id, 'repository_log_delete')
    rescue AuthorizerError
      write?
    end

    def view_log?
      authorizer.for_repo(object.id, 'repository_log_view')
    rescue AuthorizerError
      read?
    end

    def prioritize?
      authorizer.for_repo(object.id, 'repository_build_create') && build_priorities?
    rescue AuthorizerError
      read? && build_priorities?
    end
  end
end
