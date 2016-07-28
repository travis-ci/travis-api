module Travis
  module Notification
    module Publisher
      require 'travis/notification/publisher/log'
      require 'travis/notification/publisher/redis'
      require 'travis/notification/publisher/memory'
    end
  end
end
