$: << './lib'
require 'sidekiq'
require 'travis'
require 'travis/api/workers/build_cancellation'
require 'travis/support/amqp'

Travis::Database.connect
Travis::Amqp.config = Travis.config.amqp
Travis::Metrics.setup
Travis::Notification.setup

Sidekiq.configure_server do |config|
  config.redis = Travis.config.redis.merge(namespace: Travis.config.sidekiq.namespace)
end
