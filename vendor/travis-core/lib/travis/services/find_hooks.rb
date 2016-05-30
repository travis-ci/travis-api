require 'travis/services/base'

module Travis
  module Services
    class FindHooks < Base
      register :find_hooks

      def run
        current_user.service_hooks(params)
      end
    end
  end
end
