module Travis::API
  module Sidekiq
    extend self

    def gatekeeper(*args)
      gatekeeper_client.push(
        'queue' => 'build_requests',
        'class' => 'Travis::Gatekeeper::Worker',
        'args' => args
      )
    end

    private

      def client
        ::Sidekiq::Client
      end

      def gatekeeper_client
        if ENV['REDIS_GATEKEEPER_ENABLED'] != 'true'
          return client
        end

        @gatekeeper_client ||= ::Sidekiq::Client.new(gatekeeper_pool)
      end

      def gatekeeper_pool
        ::Sidekiq::RedisConnection.create(
          url: config.redis_gatekeeper.url,
          namespace: config.sidekiq.namespace,
          id: nil
        )
      end

      def config
        Travis.config
      end
  end
end
