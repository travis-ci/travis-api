require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Build < Permissions::Generic
    def cancel?
      authorizer.for_repo(object.repository_id, 'repository_build_cancel')
    rescue AuthorizerError
      cancelable?
    end

    def restart?
      authorizer.for_repo(object.repository_id, 'repository_build_restart')
    rescue AuthorizerError
      restartable?
    end

    def prioritize?
      authorizer.for_repo(object.repository_id, 'repository_build_create') && build_priorities?
    rescue AuthorizerError
      read? && build_priorities?
    end
  end
end
