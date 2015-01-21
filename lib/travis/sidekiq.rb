$: << './lib'
require 'travis/core'
require 'travis/app/workers/build_cancellation'

Sidekiq.configure_server do |config|
  config.redis = Travis.config.redis.merge(namespace: Travis.config.sidekiq.namespace)
end