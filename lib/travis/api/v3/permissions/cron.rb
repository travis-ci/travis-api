require 'travis/api/v3/permissions/generic'

module Travis::API::V3
  class Permissions::Cron < Permissions::Generic
    def delete?
      authorizer.for_repo(object.branch.repository_id, 'repository_build_delete')
    rescue AuthorizerError
      write?
    end

    def start?
      true
    end
  end
end
