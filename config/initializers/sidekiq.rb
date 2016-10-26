if Rails.env.production?
  Sidekiq.configure_client do |config|
    config.redis = { url: Travis::Config.load.redis.url }
  end

  Sidekiq.configure_server do |config|
    config.redis = { url: Travis::Config.load.redis.url }
  end
end
