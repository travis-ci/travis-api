source 'https://rubygems.org'

ruby '2.5.5' if ENV['DYNO']

# Magic Makers
gem 'rails', '~> 5.0'

# CSS/JS Stuff
gem 'chart-js-rails'
gem 'coffee-rails', '~> 4.2'
gem 'font-awesome-rails'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'

# Databases
gem 'pg'
gem 'redis', '~> 3.0'
gem 'redis-namespace'

# API stuffs
gem 'faraday', '~> 0.9.0'

# Travis Gems
gem 'travis',            github: 'travis-ci/travis.rb'
gem 'travis-config',     github: 'travis-ci/travis-config'
gem 'travis-migrations', github: 'travis-ci/travis-migrations', ref: '09dad753c986c344ae93c77b8f0110583020d'
gem 'travis-sso',        github: 'travis-ci/travis-sso'
gem 'travis-support',    github: 'travis-ci/travis-support'

# Sidekiq
gem 'foreman'
gem 'puma', '~> 3.12'
gem 'sidekiq'

# Others
gem 'bcat'
gem 'biggs'
gem 'date_validator'
gem 'logfmt'
gem 'metriks'
gem 'rollout'
gem 'rotp'
gem 'sentry-raven'
gem 'stripe'
gem 'will_paginate', '~> 3.1.0'
gem 'valvat'

group :console, :test do
  gem 'pry'
end

group :development, :test do
  gem 'factory_girl_rails', '~> 4.0'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.4'
end

group :test do
  gem 'capybara', '~> 2.7.0'
  gem 'database_cleaner'
  gem 'launchy'
  gem 'poltergeist'
  gem 'rake'
  gem 'webmock', '~> 2.3.0'
end

group :development do
  gem 'web-console', '~> 3.3'
end
