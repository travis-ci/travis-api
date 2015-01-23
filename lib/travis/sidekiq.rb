$: << './lib'
require 'sidekiq'
require 'travis'
require 'travis/api/workers/build_cancellation'
require 'travis/support/amqp'

Travis::Database.connect
Travis::Async.enabled = true
Travis::Amqp.config = Travis.config.amqp
Travis::Metrics.setup
Travis::Notification.setup

Sidekiq.configure_server do |config|
  config.redis = Travis.config.redis.merge(namespace: Travis.config.sidekiq.namespace)
end

Sidekiq.configure_client do |config|
  config.redis = Travis.config.redis.merge(size: 1, namespace: Travis.config.sidekiq.namespace)
end
