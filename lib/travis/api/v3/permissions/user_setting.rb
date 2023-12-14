module Travis::API::V3
  class Permissions::UserSetting < Permissions::Generic
    def read?
      authorizer.for_repo(object.repository.id, 'repository_settings_read')
    end

    def write?
      authorizer.for_repo(object.repository.id, 'repository_settings_create')
    end

    private

    def repository_permissions
      @repository_permissions ||= Permissions::Repository.new(access_control, object.repository)
    end
  end
end
