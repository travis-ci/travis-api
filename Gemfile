source 'https://rubygems.org'

ruby '3.2.2'

gem 'mime-types'

# travis maintained gems
gem 'gh', git: 'https://github.com/travis-ci/gh'
gem 'marginalia', git: 'https://github.com/travis-ci/marginalia'
gem 'metriks', git: 'https://github.com/travis-ci/metriks'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics'
gem 'rollout', git: 'https://github.com/travis-ci/rollout'
gem 'simple_states', git: 'https://github.com/travis-ci/simple_states', branch: 'prd-ruby-upgrade-dev'
gem 'travis-amqp', git: 'https://github.com/travis-ci/travis-amqp'
gem 'travis-config', git: 'https://github.com/travis-ci/travis-config'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps'
gem 'travis-lock', git: 'https://github.com/travis-ci/travis-lock'
gem 'travis-rollout', git: 'https://github.com/travis-ci/travis-rollout'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings'
gem 'travis-support', git: 'https://github.com/travis-ci/travis-support'

gem 'mustermann'
gem 'sinatra', '~> 3.2'
gem 'sinatra-contrib', '~> 3.2', require: nil # git: 'https://github.com/sinatra/sinatra-contrib', require: nil

gem 'active_model_serializers', '~> 0.9.9'
gem 'bunny', '~> 2.22'
gem 'dalli'
gem 'ed25519'
gem 'ipaddress', '~> 0.8.3'
gem 'librato-metrics'
gem 'nakayoshi_fork'
gem 'pry'
gem 'rack', '~> 2.2', '>= 2.2.20'
gem 'rack-attack', '~> 6'
gem 'rack-cache', git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-contrib', '>= 2.5.0'
gem 'redis-namespace'
gem 'sentry-ruby'
gem 'sidekiq', '>= 7.1.3'
gem 'simplecov'
gem 'ssh_data'
gem 'stackprof'
gem 'unicorn'
gem 'yard-sinatra', git: 'https://github.com/rkh/yard-sinatra'

gem 'memory_profiler'
gem 'rbtrace'
# gem 'allocation_tracer'

gem 'rake', '~> 13.0'
gem 'redlock'

gem 'libhoney'
gem 'opencensus'
gem 'opencensus-stackdriver', '>= 0.4.0'

gem 'faraday', '~> 2'
gem 'faraday-net_http_persistent', '~> 2'

gem 'knapsack'

gem 'logger'
gem 'rexml', '>= 3.3.9'

gem 'activerecord', '~> 7.0.8' # it was fixed in predicate_builder file to 7.0.6 but gh gem requires 7.0.8
gem 'aws-sdk-s3'
gem 'closeio', '~> 3.15'
gem 'coder', '~> 0.4.0'
gem 'composite_primary_keys', '~> 14.0'
gem 'dry-schema'
gem 'dry-struct'
gem 'dry-types'
gem 'google-cloud-storage'
gem 'hashr'
gem 'multi_json'
gem 'pg', '~> 1.5'
gem 'pusher', '~> 2.0.3'
gem 'rack-ssl', '~> 1.4'
gem 'redcarpet', '>= 3.6'
gem 'redis', '~> 5.0'
gem 'tool'
gem 'useragent'

gem 'webrick', '>= 1.8.2'

group :test do
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'hashdiff'
  gem 'mocha'
  gem 'pry-byebug'
  gem 'rack-test'
  gem 'rspec'
  gem 'rspec-its'
  gem 'timecop'
  gem 'webmock'
end

group :development do
  gem 'foreman'
  gem 'rb-fsevent', '~> 0.11'
  gem 'rerun'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end
