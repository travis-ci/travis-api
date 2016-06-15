module Travis
  module Notification
    module Publisher
      class Memory
        def publish(event)
          events << event
        end

        def events
          @events ||= []
        end
      end
  end
  end
end
