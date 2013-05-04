require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module DbFollower
      def prefer_follower
        if Travis.config.use_database_follower?
          Octopus.using(:follower) do
            yield
          end
        else
          yield
        end
      end
    end
  end
end
