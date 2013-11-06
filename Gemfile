ruby '2.0.0'

source 'https://rubygems.org'
gemspec

gem 'travis-core',     github: 'travis-ci/travis-core'
gem 'travis-support',  github: 'travis-ci/travis-support'
gem 'travis-sidekiqs', github: 'travis-ci/travis-sidekiqs', require: nil, ref: 'cde9741'
gem 'sinatra'
gem 'sinatra-contrib', require: nil #github: 'sinatra/sinatra-contrib', require: nil

gem 'unicorn'
gem 'sentry-raven',    github: 'getsentry/raven-ruby'
gem 'yard-sinatra',    github: 'rkh/yard-sinatra'
gem 'rack-contrib',    github: 'rack/rack-contrib'
gem 'rack-cache',      '~> 1.2'
gem 'rack-attack'
gem 'gh'
gem 'bunny',           '~> 0.8.0'
gem 'dalli'
gem 'pry'
gem 'metriks',         '0.9.9.5'

group :test do
  gem 'rspec',         '~> 2.13'
  gem 'factory_girl',  '~> 2.4.0'
  gem 'mocha',         '~> 0.12'
  gem 'database_cleaner', '~> 0.8.0'
end

group :development do
  gem 'foreman'
  gem 'rerun'
  # gem 'debugger'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'rake', '~> 0.9.2'
  gem 'micro_migrations', git: 'https://gist.github.com/4269321.git'
end
