module Travis
  module Addons
    module Irc
      require 'travis/addons/irc/instruments'
      require 'travis/addons/irc/event_handler'
      class Task < ::Travis::Task; end
    end
  end
end

