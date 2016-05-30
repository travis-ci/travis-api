require 'travis/notification/instrument'

module Travis
  module Notification
    class Instrument
      class EventHandler < Instrument
        attr_reader :handler, :object, :args, :result

        def initialize(message, method, status, payload)
          @handler, @args, @result = payload.values_at(:target, :args, :result)
          @object = handler.object
          super
        end

        def notify_completed
          publish
        end

        def publish(event = {})
          event = event.reverse_merge(
            :msg => "(#{handler.event}) for #<#{object.class.name} id=#{object.id}>",
            :object_type => object.class.name,
            :object_id => object.id,
            :event => handler.event
          )

          event[:payload]    = handler.payload
          event[:request_id] = object.request_id if object.respond_to?(:request_id)
          event[:repository] = object.repository.slug if object.respond_to?(:repository)
          super(event)
        end
      end
    end
  end
end
