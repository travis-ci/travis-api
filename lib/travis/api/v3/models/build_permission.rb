module Travis::API::V3
  class Models::BuildPermission
    attr_accessor :user, :permission, :role

    def initialize(attrs = {})
      @user  = attrs.fetch(:user)
      @role  = attrs.fetch(:role)
      @permission = attrs.fetch(:permission)
    end
  end
end
