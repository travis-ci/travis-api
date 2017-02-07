source 'https://rubygems.org'
gemspec

ruby '2.3.1'

gem 's3',              git: 'https://github.com/travis-ci/s3'

gem 'mime-types'

gem 'travis-support',  git: 'https://github.com/travis-ci/travis-support'
gem 'travis-amqp',     git: 'https://github.com/travis-ci/travis-amqp'
gem 'travis-config',   '~> 0.1.0'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings'
gem 'travis-sidekiqs', git: 'https://github.com/travis-ci/travis-sidekiqs'

gem 'travis-yaml',     git: 'https://github.com/travis-ci/travis-yaml'
gem 'mustermann'

gem 'unicorn'
gem 'sentry-raven'
gem 'rack-contrib'
gem 'rack-cache',      git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-timeout'
gem 'rack-attack', '5.0.0.beta1'
gem 'gh'
gem 'bunny',           '~> 0.8.0'
gem 'dalli'
gem 'pry'
gem 'metriks',         '0.9.9.6'
gem 'metriks-librato_metrics', git: 'https://github.com/eric/metriks-librato_metrics'

gem 'jemalloc'
gem 'customerio'

gem 'rake', '~> 0.9.2'

group :development, :test do
  gem 'travis-migrations', git: 'https://github.com/travis-ci/travis-migrations'
end

group :test do
  gem 'rspec',         '~> 2.13'
  gem 'rspec-its'
  gem 'factory_girl',  '~> 2.4.0'
  gem 'mocha',         '~> 0.12'
  gem 'database_cleaner', '~> 0.8.0'
  gem 'timecop',       '~> 0.8.0'
  gem 'webmock'
  gem 'sinatra-contrib', require: nil
  gem 'simplecov'
  gem 'stackprof'
end

group :development do
  gem 'foreman'
  gem 'rerun'
  gem 'rb-fsevent', '~> 0.9.1'
end
