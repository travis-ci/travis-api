ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'database_cleaner'
require 'sinatra/test_helpers'
require 'logger'
require 'gh'
require 'multi_json'

require 'travis/api/app'
require 'travis/testing/scenario'
require 'travis/testing/factories'

RSpec::Matchers.define :deliver_json_for do |type, version, params, options = {}|
  match do |response|
    actual = parse(response.body)
    expected = data(type, version, params, options)

    failure_message_for_should do
      "expected\n\n#{actual}\n\nto equal\n\n#{expected}"
    end

    actual == expected
  end

  def data(type, version, params, options)
    resource = service(type, params).run
    Travis::Api.data(resource, options.merge(version: version))
  end

  def service(service, params)
    "Travis::Services::#{service.camelize}".constantize.new(nil, params)
  end

  def parse(body)
    MultiJson.decode(body)
  end
end

Travis.logger = Logger.new(StringIO.new)
Travis::Api::App.setup

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
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with :truncation
  end

  c.before :each do
    DatabaseCleaner.start
    ::Redis.connect(url: Travis.config.redis.url).flushdb
    set_app Travis::Api::App.new
  end

  c.after :each do
    DatabaseCleaner.clean
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end
