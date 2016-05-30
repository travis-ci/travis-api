require 'travis/services/base'

module Travis
  module Services
    class FindUserPermissions < Base
      register :find_user_permissions

      def run
        scope = current_user.permissions
        scope = scope.by_roles(params[:roles].to_s.split(',')) if params[:roles]
        scope
      end
    end
  end
end
