source 'https://rubygems.org'

ruby '2.7.5'

gem 'mime-types'

gem 'travis-support',  git: 'https://github.com/travis-ci/travis-support', ref: '4dda53ffa96b804db22c261551256caa18c4a2cc'
gem 'travis-amqp',     git: 'https://github.com/travis-ci/travis-amqp'
gem 'travis-config',   git: 'https://github.com/travis-ci/travis-config', branch: 'fix-docker-redis-url'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings', branch: '6.1'
gem 'travis-lock',     git: 'https://github.com/travis-ci/travis-lock/', branch: '6.1'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps', branch: 'ga-ext_access'
gem 'travis-rollout',  '~> 0.0.2'

gem 'sinatra', '~> 2'
gem 'sinatra-contrib', require: nil #git: 'https://github.com/sinatra/sinatra-contrib', require: nil
gem 'simple_states', git: 'https://github.com/travis-ci/simple_states', branch: '6.1'

gem 'active_model_serializers', "~> 0.9.8"
gem 'unicorn'
gem 'sentry-raven'
gem 'yard-sinatra',    git: 'https://github.com/rkh/yard-sinatra'
gem 'rack-contrib', '= 2.3.0'
gem 'rack-cache',      git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-attack', '~> 5.0'
gem 'gh', git: 'https://github.com/travis-ci/gh', branch: '6.1'
gem 'bunny',           '~> 2.9.2'
gem 'dalli'
gem 'pry'
gem 'http', '~> 4'
gem 'metriks',         '0.9.9.6'
gem 'metriks-librato_metrics', git: 'https://github.com/eric/metriks-librato_metrics'
gem 'librato-metrics'
gem 'simplecov'
gem 'stackprof'
gem "ipaddress", "~> 0.8.3"
gem 'nakayoshi_fork'
gem 'sidekiq', '~> 6.4.0'
gem 'redis-namespace'
gem 'marginalia', git: 'https://github.com/travis-ci/marginalia', branch: '6.1'

gem 'rbtrace'
gem 'memory_profiler'
gem 'allocation_tracer'

gem 'redlock', '~> 1.2.2'
gem 'rake', '~> 13.0.6'

gem 'libhoney'
gem 'opencensus'
gem 'opencensus-stackdriver'

gem 'faraday'
gem 'faraday_middleware'

gem 'knapsack'

gem 'pg',                     '~> 1.3'
gem 'composite_primary_keys', '~> 13.0.3'
gem 'redcarpet',              '>= 3.2.3'
gem 'rack-ssl',               '~> 1.3', '>= 1.3.3'
gem 'memcachier'
gem 'useragent'
gem 'tool'
gem 'google-api-client', '~> 0.9.4'
gem 'google-protobuf',   '~> 3.19.6'
gem 'fog-aws',           '~> 0.12.0'
gem 'fog-google',        '~> 0.4.2'
gem 'activerecord',      '~> 6.1.6.1'
gem 'rollout',           '~> 1.1.0'
gem 'coder',             '~> 0.4.0'
gem 'virtus',            '~> 1.0.0'
gem 'redis',             '~> 4.2.0'
gem 'hashr'
gem 'pusher',            '~> 0.14.0'
gem 'multi_json'
gem 'addressable',       '~> 2.8.0'
gem 'rack',              '~> 2.2.3'
gem 'os',                '~> 1.1.4'

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
