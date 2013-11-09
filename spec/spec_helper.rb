ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'database_cleaner'
require 'sinatra/test_helpers'
require 'logger'
require 'gh'
require 'multi_json'

require 'travis/api/app'
require 'travis/testing'
require 'travis/testing/scenario'
require 'travis/testing/factories'
require 'support/matchers'

Travis.logger = Logger.new(StringIO.new)
Travis::Api::App.setup
Travis.config.client_domain = "www.example.com"

module TestHelpers
  include Sinatra::TestHelpers

  def custom_endpoints
    @custom_endpoints ||= []
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
  c.expect_with :rspec, :stdlib
  c.include TestHelpers

  c.before :suite do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :truncation
    Scenario.default
  end

  c.before :each do
    DatabaseCleaner.start
    ::Redis.connect(url: Travis.config.redis.url).flushdb
    Travis.config.oauth2 ||= {}
    Travis.config.oauth2.scope = "user:email,public_repo"
    set_app Travis::Api::App.new
  end

  c.after :each do
    DatabaseCleaner.clean
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end
