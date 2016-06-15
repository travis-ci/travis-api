require 'travis/addons/webhook/instruments'
require 'travis/event/handler'

# TODO include_logs? has been removed. gotta be deprecated!
#
module Travis
  module Addons
    module Webhook

      # Sends build notifications to webhooks as defined in the configuration
      # (`.travis.yml`).
      class EventHandler < Event::Handler
        EVENTS = /build:(started|finished)/

        def initialize(*)
          super
        end

        def handle?
          targets.present? && config.send_on?(:webhooks, event.split(':').last)
        end

        def handle
          Travis::Addons::Webhook::Task.run(:webhook, webhook_payload, targets: targets, token: request['token'])
        end

        def webhook_payload
          Api.data(object, :for => 'webhook', :type => 'build/finished', :version => 'v1')
        end

        def targets
          @targets ||= config.notification_values(:webhooks, :urls)
        end

        Instruments::EventHandler.attach_to(self)
      end
    end
  end
end
