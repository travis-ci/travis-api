module Travis
  module Addons
    module Hipchat
      require 'travis/addons/hipchat/instruments'
      require 'travis/addons/hipchat/event_handler'
      class Task < ::Travis::Task; end
    end
  end
end

