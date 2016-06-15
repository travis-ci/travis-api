module Travis
  module Addons
    module Pushover
      module Instruments
        require 'travis/addons/pushover/instruments'
      end

      require 'travis/addons/pushover/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end
