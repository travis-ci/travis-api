require 'sidekiq/worker'
require 'multi_json'

module Travis
  module Sidekiq
    class BuildRestart
      include ::Sidekiq::Worker
      sidekiq_options queue: :hub

      def perform(payload)
        ::Sidekiq::Client.push(
              'queue'   => 'hub',
              'class'   => 'Travis::Hub::Sidekiq::Worker',
              'args'    => ["build:restart", payload]
            )
      end

    end
  end
end
