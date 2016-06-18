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

require 'travis/api/app'
require 'travis/testing'
require 'travis/testing/scenario'
require 'travis/testing/factories'
require 'travis/testing/matchers'
require 'support/formats'
require 'support/gcs'
require 'support/matchers'
require 'support/payloads'
require 'support/private_key'
require 'support/s3'
require 'support/test_helpers'

RSpec.configure do |c|
  c.mock_framework = :mocha
  c.expect_with :rspec
  c.include TestHelpers

  c.before :suite do
    Travis.logger = Logger.new(StringIO.new)
    Travis::Api::App.setup
    Travis.config.client_domain = "www.example.com"
    Travis.config.endpoints.ssh_key = true

    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :transaction

    Scenario.default
  end

  c.before :each do
    DatabaseCleaner.start
    Redis.new.flushall
    Travis.config.oauth2.scope = "user:email,public_repo"
    # set_app Travis::Api::App.new
  end

  c.before :each, set_app: true do
    set_app Travis::Api::App.new
  end

  c.after :each do
    # puts DatabaseCleaner.connections.map(&:strategy).map(&:class).map(&:name).join(', ')
    DatabaseCleaner.clean
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end
