module Travis::API::V3
  class Permissions::UserSetting < Permissions::Generic
    def read?
      repository_permissions.read?
    end

    def write?
      repository_permissions.write?
    end

    private

    def repository_permissions
      @repository_permissions ||= Permissions::Repository.new(access_control, object.repository)
    end
  end
end
