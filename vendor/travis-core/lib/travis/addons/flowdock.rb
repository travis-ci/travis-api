module Travis
  module Addons
    module Flowdock
      require 'travis/addons/flowdock/instruments'
      require 'travis/addons/flowdock/event_handler'
      class Task < ::Travis::Task; end
    end
  end
end

