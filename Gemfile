source 'https://rubygems.org'

# Magic Makers
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'

# CSS/JS Stuff
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.2'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'font-awesome-rails'
gem 'chart-js-rails'

# Databases
gem 'pg'
gem 'redis', '~> 3.0'
gem 'redis-namespace'

# API stuffs
gem 'faraday', '~> 0.9.0'

# Travis Gems
gem 'travis-migrations', github: 'travis-ci/travis-migrations'
gem 'travis-sso',        github: 'travis-ci/travis-sso'
gem 'travis-config',     github: 'travis-ci/travis-config'
gem 'travis-topaz',      github: 'travis-ci/travis-topaz-gem'
gem 'travis-support',    github: 'travis-ci/travis-support'
gem 'travis',            github: 'travis-ci/travis.rb'

gem 'rollout'

gem 'metriks'

gem 'bcat'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Sidekiq
gem 'puma', '~> 3.0'
gem 'sidekiq'
gem 'foreman'

# Address formatting
gem 'biggs'

# Date validator
gem 'date_validator'

group :console, :test do
  gem 'pry'
  # gem 'pry-byebug'
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
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 3.3'
end
