module Travis
  module Notification
    module Publisher
      class Log
        def publish(event)
          return if ignore?(event)

          level = event.key?(:exception) ? :error : :info
          message = event[:message]
          message = "#{message} (#{'%.5f' % event[:duration]}s)" if event[:duration]
          log(level, message)

          if level == :error || Travis.logger.level == ::Logger::DEBUG
            event.each do |key, value|
              next if key == :message
              level = event.key?(:exception) ? :error : :debug
              log(level, "  #{key}: #{value.inspect}")
            end
          end
        end

        def log(level, msg)
          Travis.logger.send(level, msg)
        end

        def ignore?(event)
          event_received?(event) && !sync_or_request_handler?(event)
        end

        def event_received?(event)
          event[:event].end_with?("received")
        end

        # TODO why do ignore these again?
        def sync_or_request_handler?(event)
          msg = event[:message]
          msg && msg =~ /Travis::Hub::Handler::(Sync|Request)#handle/
        end
      end
    end
  end
end
