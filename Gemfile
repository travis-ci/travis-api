source 'https://rubygems.org'

ruby '2.1.8' if ENV.key?('DYNO')

group :travis do
  # should this stuff be global or stay in here?
  gem 'rails', '4.2.5'
  gem 'activeresource'
  gem 'sass-rails', '~> 5.0'
  gem 'jquery-rails'

  # Not sure if I need/want the stuff below but just in case
  gem 'uglifier', '>= 1.3.0'
  gem 'turbolinks'
  gem 'coffee-rails', '~> 4.1.0'
end

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

group :development do
  # gem 'web-console', '~> 2.0'
end

group :test do
 gem 'rake'
end

