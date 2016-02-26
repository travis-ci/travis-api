source 'https://rubygems.org'

ruby '2.1.8' if ENV.key?('DYNO')

# Magic Makers
gem 'rails', '4.2.5'
gem 'her'

# Travis things
gem 'travis-sso', github:'travis-ci/travis-sso'

# Bootstrap/Sass stuff
gem 'sass-rails', '~> 5.0'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'font-awesome-sass'

# JS Stuff
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'

# Not sure if I need this
gem 'turbolinks'

group :server do
  # stuff will go here eventually
end

group :console, :test do
  gem 'pry'
  # gem 'pry-byebug'
end

group :doc do
  gem 'sdoc', '~> 0.4.0'
end

group :test do
  gem 'rake'
  gem 'rspec-rails', '~> 3.0'
  gem 'webmock'
  gem 'vcr'
end

