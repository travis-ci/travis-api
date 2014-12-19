source 'https://rubygems.org'
gemspec

gem 's3',              github: 'travis-ci/s3'

gem 'travis-core',     github: 'travis-ci/travis-core'
gem 'travis-support',  github: 'travis-ci/travis-support'
gem 'travis-config',   '~> 0.1.0'
gem 'travis-sidekiqs', github: 'travis-ci/travis-sidekiqs', require: nil, ref: 'cde9741'
gem 'travis-yaml',     github: 'travis-ci/travis-yaml'
gem 'sinatra'
gem 'sinatra-contrib', require: nil #github: 'sinatra/sinatra-contrib', require: nil

gem 'active_model_serializers'
gem 'unicorn'
gem 'sentry-raven',    github: 'getsentry/raven-ruby'
gem 'yard-sinatra',    github: 'rkh/yard-sinatra'
gem 'rack-contrib',    github: 'rack/rack-contrib'
gem 'rack-cache',      github: 'rtomayko/rack-cache'
gem 'rack-attack'
gem 'gh'
gem 'bunny',           '~> 0.8.0'
gem 'dalli'
gem 'pry'
gem 'metriks',         '0.9.9.6'
gem 'metriks-librato_metrics', github: 'eric/metriks-librato_metrics'
gem 'micro_migrations'

group :test do
  gem 'rspec',         '~> 2.13'
  gem 'factory_girl',  '~> 2.4.0'
  gem 'mocha',         '~> 0.12'
  gem 'database_cleaner', '~> 0.8.0'
end

group :development do
  gem 'foreman'
  gem 'rerun'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'rake', '~> 0.9.2'
end
