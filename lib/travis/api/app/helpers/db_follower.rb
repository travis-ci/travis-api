require 'travis/api/app'

class Travis::Api::App
  module Helpers
    module DbFollower
      def prefer_follower
        if Travis::Features.feature_active?(:api_use_db_follower)
          Travis::Model.using_follower do
            yield
          end
        else
          yield
        end
      end
    end
  end
end
