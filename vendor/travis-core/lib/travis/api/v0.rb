module Travis
  module Api
    # V0 is an internal api that we can change at any time
    module V0
      require 'travis/api/v0/event'
      require 'travis/api/v0/notification'
      require 'travis/api/v0/pusher'
      require 'travis/api/v0/worker'
    end
  end
end
