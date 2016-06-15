require 'travis/addons/pushover/instruments'
require 'travis/event/handler'

module Travis
  module Addons
    module Pushover

      # Publishes a build notification to pushover users as defined in the
      # configuration (`.travis.yml`).
      #
      # Credentials are encrypted using the repository's ssl key.
      class EventHandler < Event::Handler
        API_VERSION = 'v2'

        EVENTS = /build:finished/

        def handle?
          !pull_request? && users.present? && api_key.present? && config.send_on_finished_for?(:pushover)
        end

        def handle
          Travis::Addons::Pushover::Task.run(:pushover, payload, users: users, api_key: api_key)
        end

        def users
          @users ||= config.notification_values(:pushover, :users)
        end

        def api_key
          @api_key ||= config.notifications[:pushover][:api_key]
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end
