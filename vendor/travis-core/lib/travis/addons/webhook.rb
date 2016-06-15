module Travis
  module Addons
    module Webhook
      require 'travis/addons/webhook/instruments'
      require 'travis/addons/webhook/event_handler'

      class Task < ::Travis::Task; end
    end
  end
end

