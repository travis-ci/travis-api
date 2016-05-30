module Travis
  module Addons
    module Campfire
      module Instruments
        require 'travis/addons/campfire/instruments'
      end

      require 'travis/addons/campfire/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end
