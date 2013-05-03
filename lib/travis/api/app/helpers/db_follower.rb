require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module DbFollower
      def prefer_follower
        Octopus.using(:follower) do
          yield
        end
      end
    end
  end
end
