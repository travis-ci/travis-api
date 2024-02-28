source 'https://rubygems.org'

ruby '3.2.2'

gem 'mime-types'

gem 'travis-support',  git: 'https://github.com/travis-ci/travis-support', branch: 'prd-ruby-upgrade-dev-o'
gem 'travis-amqp',     git: 'https://github.com/travis-ci/travis-amqp', branch: 'prd-ruby-upgrade-dev'
gem 'travis-config',  git: 'https://github.com/travis-ci/travis-config', branch: 'prd-ruby-upgrade-dev'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings', branch: 'prd-ruby-upgrade-dev'
gem 'travis-lock',     git: 'https://github.com/travis-ci/travis-lock', branch: 'prd-ruby-upgrade-dev'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps', branch: 'prd-ruby-upgrade-dev'
gem 'travis-rollout',  '~> 0.0.2'

gem 'mustermann'
gem 'sinatra'
gem 'sinatra-contrib', require: nil #git: 'https://github.com/sinatra/sinatra-contrib', require: nil

gem 'simple_states',  git: 'https://github.com/travis-ci/simple_states', branch: 'prd-ruby-upgrade-dev'

gem 'active_model_serializers' , '~> 0.9.9'
gem 'unicorn'
gem 'sentry-ruby'
gem 'yard-sinatra',    git: 'https://github.com/rkh/yard-sinatra'
gem 'rack', '~> 2.2'
gem 'rack-contrib'
gem 'rack-cache',      git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-attack', '~> 6'
gem 'gh',   git: 'https://github.com/travis-ci/gh', branch: 'prd-ruby-upgrade-dev'
gem 'bunny',           '~> 2.22'
gem 'dalli'
gem 'pry'
gem 'metriks',        git: 'https://github.com/travis-ci/metriks', branch: 'prd-ruby-upgrade-dev'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics', branch: 'prd-ruby-upgrade-dev'
gem 'librato-metrics'
gem 'simplecov'
gem 'stackprof'
gem "ipaddress", "~> 0.8.3"
gem 'nakayoshi_fork'
gem 'sidekiq'
gem 'redis-namespace'
gem 'marginalia', git: 'https://github.com/travis-ci/marginalia', branch: 'prd-ruby-upgrade-dev'

gem 'rbtrace'
gem 'memory_profiler'
gem 'allocation_tracer'

gem 'redlock'
gem 'rake', '~> 13.0'

gem 'libhoney'
gem 'opencensus'
gem 'opencensus-stackdriver'

gem 'faraday', '~> 2'
gem 'faraday-net_http_persistent', '~> 2'

gem 'knapsack'

gem 'pg',                     '~> 1.5'
gem 'composite_primary_keys', '~> 14.0'
gem 'redcarpet',              '>= 3.6'
gem 'rack-ssl',               '~> 1.4'
gem 'useragent'
gem 'tool'
gem 'google-cloud-storage'
gem 'aws-sdk-s3'
gem 'activerecord',      '~> 7'
gem 'rollout',           git: 'https://github.com/travis-ci/rollout', branch: 'prd-ruby-upgrade-dev'
gem 'coder',             '~> 0.4.0'
gem 'dry-types'
gem 'dry-struct'
gem 'dry-schema'
gem 'redis',             '~> 5.0'
gem 'hashr'
gem 'pusher',            '~> 2.0.3'
gem 'multi_json'
gem 'closeio',           '~> 3.15'

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
  gem 'rb-fsevent', '~> 0.11'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
