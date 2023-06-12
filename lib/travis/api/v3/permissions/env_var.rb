module Travis::API::V3
  class Permissions::EnvVar < Permissions::Generic
    def read?
      authorizer.for_repo(object.repository_id, 'repository_settings_read')
    rescue AuthorizerError
      repository_permissions.read?
    end

    def write?
      authorizer.for_repo(object.repository_id, 'repository_settings_create')
    rescue AuthorizerError
      repository_permissions.write?
    end

    private

    def repository_permissions
      @repository_permissions ||= Permissions::Repository.new(access_control, object.repository)
    end
  end
end
