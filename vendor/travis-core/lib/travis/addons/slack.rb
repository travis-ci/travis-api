module Travis
  module Addons
    module Slack
      require 'travis/addons/slack/instruments'
      require 'travis/addons/slack/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end

