source 'https://rubygems.org'

ruby '2.5.5' if ENV['DYNO']

# Magic Makers
gem 'rails', '~> 5.0'

# CSS/JS Stuff
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'font-awesome-rails'
gem 'chart-js-rails'
gem 'sass-rails', '~> 5.0'

# Databases
gem 'pg'
gem 'redis', '~> 3.0'
gem 'redis-namespace'

# API stuffs
gem 'faraday', '~> 0.9.0'

# Travis Gems
gem 'travis-migrations', github: 'travis-ci/travis-migrations', ref: '09dad753c986c344ae93c77b8f0110583020d'
gem 'travis-sso',        github: 'travis-ci/travis-sso'
gem 'travis-config',     github: 'travis-ci/travis-config'
gem 'travis-support',    github: 'travis-ci/travis-support'
gem 'travis',            github: 'travis-ci/travis.rb'

# Sidekiq
gem 'puma', '~> 3.12'
gem 'sidekiq'
gem 'foreman'

# Others
gem 'bcat'
gem 'biggs'
gem 'date_validator'
gem 'gh'
gem 'metriks'
gem 'rollout'
gem 'rotp'
gem 'sentry-raven'
gem 'will_paginate', '~> 3.1.0'
gem 'logfmt'

group :console, :test do
  gem 'pry'
end

group :development, :test do
  gem 'rspec-rails', '~> 3.4'
  gem 'factory_girl_rails', '~> 4.0'
  gem 'pry-rails'
end

group :test do
  gem 'rake'
  gem 'database_cleaner'
  gem 'webmock', '~> 2.1.0'
  gem 'capybara', '~> 2.7.0'
  gem 'poltergeist'
  gem 'launchy'
end

group :development do
  gem 'web-console', '~> 3.3'
end
