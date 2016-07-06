source 'https://rubygems.org'

# Magic Makers
gem 'rails', '4.2.6'

# JS Stuff
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'

# Use postgresql as the database for Active Record
gem 'pg'

# API stuffs
gem 'faraday', '~> 0.9.0'

# Travis Migrations for the db
gem 'travis-migrations', github: 'travis-ci/travis-migrations'
gem 'travis-pro-migrations',  git: "https://fba4602ab138c5b2c8d48ae32a67aedeefc5e939:x-oauth-basic@github.com/travis-pro/travis-pro-migrations.git", require: 'travis/pro/migrations'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Not sure if I need this
gem 'turbolinks'

group :server do
  # stuff will go here eventually
end

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
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'
end
