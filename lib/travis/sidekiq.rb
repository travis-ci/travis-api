$: << 'lib'

require 'sidekiq'
require 'travis'
require 'travis/support/amqp'

pool_size = ENV['SIDEKIQ_DB_POOL_SIZE'] || 5
Travis.config.database[:pool] = pool_size.to_i
Travis::Database.connect

Travis::Async.enabled = true
Travis::Amqp.config = Travis.config.amqp.to_h
Travis::Notification.setup

Sidekiq.configure_server do |config|
  cfg = Travis.config.redis.to_h.merge(id: nil)
  cfg = cfg.merge(ssl_params: Travis.redis_ssl_params) if Travis.config.redis.ssl
  config.redis = cfg
end

Sidekiq.configure_client do |config|
  cfg = Travis.config.redis.to_h.merge(size: 1, id: nil)
  cfg = cfg.merge(ssl_params: Travis.redis_ssl_params) if Travis.config.redis.ssl
  config.redis = cfg
end
