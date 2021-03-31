require 'travis_config'

if Rails.env.production?
  travis_config = TravisConfig.load

  Sidekiq.configure_client do |config|
    config.redis = { url: travis_config.redis.url, id: nil }
  end

  Sidekiq.configure_server do |config|
    config.redis = { url: travis_config.redis.url, id: nil }
  end
end
