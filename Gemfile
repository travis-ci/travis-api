source 'https://rubygems.org'

ruby '2.6.5'

gem 's3',              git: 'https://github.com/travis-ci/s3'

gem 'mime-types'

gem 'travis-support',  git: 'https://github.com/travis-ci/travis-support'
gem 'travis-amqp',     git: 'https://github.com/travis-ci/travis-amqp'
gem 'travis-config',   git: 'https://github.com/travis-ci/travis-config', branch: 'fix-docker-redis-url'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings'
gem 'travis-lock',     git: 'https://github.com/travis-ci/travis-lock'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps'
gem 'travis-rollout',  '~> 0.0.2'

gem 'mustermann'
gem 'sinatra'
gem 'sinatra-contrib', require: nil #git: 'https://github.com/sinatra/sinatra-contrib', require: nil

gem 'simple_states',   '1.0.2'

gem 'active_model_serializers'
gem 'unicorn'
gem 'sentry-raven', '~> 2.11.3'
gem 'yard-sinatra',    git: 'https://github.com/rkh/yard-sinatra'
gem 'rack', '>= 2.1.4'
gem 'rack-contrib'
gem 'rack-cache',      git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-attack', '~> 5.0'
gem 'gh', git: 'https://github.com/travis-ci/gh'
gem 'bunny',           '~> 2.9.2'
gem 'dalli'
gem 'pry'
gem 'metriks',         '0.9.9.6'
gem 'metriks-librato_metrics', git: 'https://github.com/eric/metriks-librato_metrics'
gem 'librato-metrics'
gem 'simplecov'
gem 'stackprof'
gem "ipaddress", "~> 0.8.3"
gem 'nakayoshi_fork'
gem 'sidekiq'
gem 'redis-namespace'
gem 'marginalia', git: 'https://github.com/travis-ci/marginalia'

gem 'rbtrace'
gem 'memory_profiler'
gem 'allocation_tracer'

gem 'redlock'
gem 'rake', '~> 12.3.3'

gem 'libhoney'
gem 'opencensus'
gem 'opencensus-stackdriver'

gem 'faraday'
gem 'faraday_middleware'

gem 'knapsack'

gem 'pg',                     '~> 0.21'
gem 'composite_primary_keys', '~> 8.0'
gem 'redcarpet',              '>= 3.2.3'
gem 'rack-ssl',               '~> 1.3', '>= 1.3.3'
gem 'memcachier'
gem 'useragent'
gem 'tool'
gem 'google-api-client', '~> 0.9.4'
gem 'fog-aws',           '~> 0.12.0'
gem 'fog-google',        '~> 0.4.2'
gem 'activerecord',      '~> 4.2'
gem 'rollout',           '~> 1.1.0'
gem 'coder',             '~> 0.4.0'
gem 'virtus',            '~> 1.0.0'
gem 'redis',             '~> 3.0'
gem 'hashr'
gem 'pusher',            '~> 0.14.0'
gem 'multi_json'
gem 'closeio',           '~> 3.5'

group :test do
  gem 'rspec'
  gem 'rspec-its'
  gem 'factory_bot'
  gem 'mocha'
  gem 'database_cleaner'
  gem 'timecop'
  gem 'webmock'
  gem 'hashdiff'
  gem 'pry-byebug'
  gem 'rack-test'
end

group :development do
  gem 'foreman'
  gem 'rerun'
  gem 'rb-fsevent', '~> 0.9.1'
end
