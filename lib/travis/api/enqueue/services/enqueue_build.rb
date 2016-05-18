module Travis
  module Enqueue
    module Services

      class EnqueueBuild

        def self.push(event, payload)
          ::Sidekiq::Client.push(
                'queue'   => 'hub',
                'class'   => 'Travis::Hub::Sidekiq::Worker',
                'args'    => [event, payload]
              )
        end
      end

    end
  end
end
