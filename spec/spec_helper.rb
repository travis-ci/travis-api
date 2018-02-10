# require 'knapsack'
#
# Knapsack::Adapters::RspecAdapter.bind

ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'support/coverage' unless ENV['SKIP_COVERAGE']

require 'rspec'
require 'rspec/its'
require 'database_cleaner'
require 'logger'
require 'gh'
require 'multi_json'
require 'pry'
require 'stackprof'
require 'webmock/rspec'

require 'active_record'
ActiveRecord::Base.raise_in_transactional_callbacks = true

require 'travis/api/app'
require 'travis/testing'
require 'travis/testing/scenario'
require 'travis/testing/factories'
require 'travis/testing/matchers'
require 'auth/helpers'
require 'support/env'
require 'support/formats'
require 'support/gcs'
require 'support/matchers'
require 'support/payloads'
require 'support/private_key'
require 'support/s3'
require 'support/ssl_keys'
require 'support/test_helpers'
require 'support/shared_examples'
require 'support/active_record'

FactoryBot = FactoryGirl

module TestHelpers
  include Sinatra::TestHelpers

  def custom_endpoints
    @custom_endpoints ||= []
  end

  def add_settings_endpoint(name, options = {})
    if options[:singleton]
      Travis::Api::App::SingletonSettingsEndpoint.subclass(name)
    else
      Travis::Api::App::SettingsEndpoint.subclass(name)
    end
    set_app Travis::Api::App.new
  end

  def add_endpoint(prefix, &block)
    endpoint = Sinatra.new(Travis::Api::App::Endpoint, &block)
    endpoint.set(prefix: prefix)
    set_app Travis::Api::App.new
    custom_endpoints << endpoint
  end

  def parsed_body
    MultiJson.decode(body)
  end
end

RSpec.configure do |c|
  c.mock_framework = :mocha
  c.expect_with :rspec
  c.include TestHelpers
  c.include Support::Env
  c.include Support::AuthHelpers, auth_helpers: true

  # for auth tests against staging, how the hell does this work, if at all
  # c.filter_run mode: :private, repo: :private
  # c.filter_run_excluding mode: :public, repo: :public

  c.before :suite do
    Travis.testing = true
    Travis.logger = Logger.new(StringIO.new)
    Travis::Api::App.setup
    Travis.config.client_domain = "www.example.com"
    Travis.config.endpoints.ssh_key = true

    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction

    # This sets up a scenario in the db as an initial state. The db will be
    # rolled back to this state after each test. Several tests in ./spec depend
    # on this scenario, so this gives a performance benefit, but also can be
    # confusing.
    Scenario.default
  end

  c.before :each do
    DatabaseCleaner.start
    Redis.new.flushall
    Travis.config.public_mode = true
    Travis.config.host = 'travis-ci.org'
    Travis.config.oauth2.scope = "user:email,public_repo"
  end

  c.before :each, set_app: true do
    set_app Travis::Api::App.new
  end

  c.after :each do
    DatabaseCleaner.clean
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end

require 'timecop'
Timecop.freeze(Time.now.utc)
