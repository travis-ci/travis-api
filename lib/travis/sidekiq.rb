#$: << './lib'
require 'sidekiq'
require 'travis'
require 'travis/api/workers/build_cancellation'
require 'travis/api/workers/build_restart'
require 'travis/api/workers/job_cancellation'
require 'travis/api/workers/job_restart'
require 'travis/support/amqp'

pool_size = ENV['SIDEKIQ_DB_POOL_SIZE'] || 5
Travis.config.database[:pool] = pool_size.to_i
Travis.config.logs_database[:pool] = pool_size.to_i
Travis::Database.connect

if Travis.config.logs_database
  Travis::LogsModel.establish_connection 'logs_database'
end

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
