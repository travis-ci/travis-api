source 'https://rubygems.org'

ruby '2.5.5' if ENV['DYNO']

# Magic Makers
gem 'rails', '= 5.2.5'

# for railties app_generator_test
gem "bootsnap", ">= 1.1.0", require: false

# Active Support.
gem "listen", ">= 3.0.5", "< 3.2", require: false

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
gem 'faraday', '~> 1.0'

# Travis Gems
gem 'travis',            github: 'travis-ci/travis.rb'
gem 'travis-config',     github: 'travis-ci/travis-config'
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
gem 'will_paginate', '~> 3.1.0'

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
  gem 'webmock', '~> 2.3.2'
end

group :development do
  gem 'web-console', '~> 3.3'
end
