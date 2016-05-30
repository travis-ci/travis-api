module Travis
  module Addons
    module Email

      require 'travis/addons/email/instruments'
      require 'travis/addons/email/event_handler'
      class Task < ::Travis::Task; end
    end
  end
end
