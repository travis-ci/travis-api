# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
abort("The DATABASE_URL is set. Remove it and try again.") if ENV['DATABASE_URL'].present?

require 'spec_helper'
require 'rspec/rails'
require 'support/factory_girl'

# load up Capybara
require 'capybara/rspec'
require 'capybara/rails'

# load up Poltergeist (not turning off js errors, b/c this is our app, we want to know about errors!)
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

# Database Cleaner
require 'database_cleaner'

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  config.render_views

  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation, except: %w{ar_internal_metadata})
  end

  config.before(:each) do
    DatabaseCleaner.strategy = Capybara.current_driver == :rack_test ? :transaction : :truncation
    DatabaseCleaner.clean
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Travis::DataStores.redis.flushall
  end

  config.before(type: :feature) do
    # simulate login of admin travisbot with 2fa setup
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(create(:user))
    Travis::DataStores.redis.set('admin-v2:otp:travisbot', 'secret')
  end

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end
