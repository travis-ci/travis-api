require 'raven'

if ENV['SENTRY_DSN']
  Raven.configure do |config|
    config.dsn = ENV['SENTRY_DSN']
  end
  raise Exception.new('Sentry test!')
end