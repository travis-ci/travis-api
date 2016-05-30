module Travis
  module Addons
    module Sqwiggle

      # Publishes a build notification to sqwiggle rooms as defined in the
      # configuration (`.travis.yml`).
      #
      # sqwiggle credentials are encrypted using the repository's ssl key.
      class EventHandler < Event::Handler

        EVENTS = /build:finished/

        def handle?
          !pull_request? && targets.present? && config.send_on_finished_for?(:sqwiggle)
        end

        def handle
          Travis::Addons::Sqwiggle::Task.run(:sqwiggle, payload, targets: targets)
        end

        def targets
          @targets ||= config.notification_values(:sqwiggle, :rooms)
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end

