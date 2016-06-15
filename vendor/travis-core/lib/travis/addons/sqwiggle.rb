module Travis
  module Addons
    module Sqwiggle
      require 'travis/addons/sqwiggle/instruments'
      require 'travis/addons/sqwiggle/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end

