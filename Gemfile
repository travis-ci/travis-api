source 'https://rubygems.org'

ruby '3.2.2'

gem 'mime-types'

# travis maintained gems
gem 'travis-support',  git: 'https://github.com/travis-ci/travis-support'
gem 'travis-amqp',     git: 'https://github.com/travis-ci/travis-amqp'
gem 'travis-config',  git: 'https://github.com/travis-ci/travis-config'
gem 'travis-settings', git: 'https://github.com/travis-ci/travis-settings'
gem 'travis-lock',     git: 'https://github.com/travis-ci/travis-lock'
gem 'travis-github_apps', git: 'https://github.com/travis-ci/travis-github_apps'
gem 'travis-rollout',  git: 'https://github.com/travis-ci/travis-rollout'
gem 'simple_states',  git: 'https://github.com/travis-ci/simple_states', branch: 'prd-ruby-upgrade-dev'
gem 'metriks',        git: 'https://github.com/travis-ci/metriks'
gem 'metriks-librato_metrics', git: 'https://github.com/travis-ci/metriks-librato_metrics'
gem 'marginalia', git: 'https://github.com/travis-ci/marginalia'
gem 'gh',   git: 'https://github.com/travis-ci/gh'
gem 'rollout',           git: 'https://github.com/travis-ci/rollout'

gem 'mustermann'
gem 'sinatra'
gem 'sinatra-contrib', require: nil #git: 'https://github.com/sinatra/sinatra-contrib', require: nil

gem 'active_model_serializers' , '~> 0.9.9'
gem 'unicorn'
gem 'sentry-ruby'
gem 'yard-sinatra',    git: 'https://github.com/rkh/yard-sinatra'
gem 'rack', '~> 2.2'
gem 'rack-contrib'
gem 'rack-cache',      git: 'https://github.com/rtomayko/rack-cache'
gem 'rack-attack', '~> 6'
gem 'bunny',           '~> 2.22'
gem 'dalli'
gem 'pry'
gem 'librato-metrics'
gem 'simplecov'
gem 'stackprof'
gem "ipaddress", "~> 0.8.3"
gem 'nakayoshi_fork'
gem 'sidekiq'
gem 'redis-namespace'
gem 'ssh_data'
gem 'ed25519'

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
gem 'activerecord',      '~> 7.0.8' # it was fixed in predicate_builder file to 7.0.6 but gh gem requires 7.0.8
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
