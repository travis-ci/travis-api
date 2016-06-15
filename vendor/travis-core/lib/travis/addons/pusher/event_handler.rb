require 'travis/addons/pusher/instruments'
require 'travis/event/handler'

module Travis
  module Addons
    module Pusher

      # Notifies registered clients about various state changes through Pusher.
      class EventHandler < Event::Handler
        EVENTS = [
          /^build:(created|received|started|finished|canceled)/,
          /^job:test:(created|received|started|log|finished|canceled)/
        ]

        attr_reader :channels, :pusher_payload

        def initialize(*)
          super
          @pusher_payload = Api.data(object, :for => 'pusher', :type => type, :params => data) if handle?
        end

        def handle?
          true
        end

        def handle
          Travis::Addons::Pusher::Task.run(queue, pusher_payload, :event => event)
        end

        private

          def type
            event.sub('test:', '').sub(':', '/')
          end

          def queue
            if Travis::Features.enabled_for_all?(:"pusher-live") ||
               Travis::Features.repository_active?(:"pusher-live", repository_id)
              :"pusher-live"
            else
              :pusher
            end
          end

          def repository_id
            if payload && payload['repository'] && payload['repository']['id']
              payload['repository']['id']
            elsif object && object.repository && object.repository.id
              object.repository.id
            end
          end

          Instruments::EventHandler.attach_to(self)
      end
    end
  end
end
