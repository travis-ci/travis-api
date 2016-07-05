require 'travis/services/base'

module Travis
  module Services
    class FindUserBroadcasts < Base
      register :find_user_broadcasts

      def run
        Broadcast.by_user(current_user)
      end
    end
  end
end
