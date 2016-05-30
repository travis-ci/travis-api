require 'travis/addons/irc/instruments'
require 'travis/event/handler'

module Travis
  module Addons
    module Irc

      # Publishes a build notification to IRC channels as defined in the
      # configuration (`.travis.yml`).
      class EventHandler < Event::Handler
        API_VERSION = 'v2'

        EVENTS = 'build:finished'

        def handle?
          !pull_request? && channels.present? && config.send_on_finished_for?(:irc)
        end

        def handle
          Travis::Addons::Irc::Task.run(:irc, payload, channels: channels)
        end

        def channels
          @channels ||= config.notification_values(:irc, :channels)
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end

