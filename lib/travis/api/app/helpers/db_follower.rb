require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module DbFollower
      def prefer_follower
        yield
      end
    end
  end
end
