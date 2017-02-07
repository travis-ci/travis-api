require 'sidekiq'

module Travis::Setup
  module Sidekiq
    extend self

    def setup
      return unless Travis.production?
      ::Sidekiq.configure_client do |config|
        config.redis = Travis.config.redis.merge(size: 1, namespace: Travis.config.sidekiq.namespace)
      end
    end
  end
end
