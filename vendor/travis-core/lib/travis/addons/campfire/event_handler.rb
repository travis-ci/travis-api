require 'travis/addons/campfire/instruments'
require 'travis/event/handler'

module Travis
  module Addons
    module Campfire

      # Publishes a build notification to campfire rooms as defined in the
      # configuration (`.travis.yml`).
      #
      # Campfire credentials are encrypted using the repository's ssl key.
      class EventHandler < Event::Handler
        API_VERSION = 'v2'

        EVENTS = /build:finished/

        def handle?
          !pull_request? && targets.present? && config.send_on_finished_for?(:campfire)
        end

        def handle
          Travis::Addons::Campfire::Task.run(:campfire, payload, targets: targets)
        end

        def targets
          @targets ||= config.notification_values(:campfire, :rooms)
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end
