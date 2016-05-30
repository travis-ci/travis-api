module Travis
  module Addons
    module Pusher
      require 'travis/addons/pusher/instruments'
      require 'travis/addons/pusher/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end

