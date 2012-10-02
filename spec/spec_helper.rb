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

RSpec::Matchers.define :deliver_json_for do |resource, options = {}|
  match do |response|
    actual = parse(response.body)
    expected = Travis::Api.data(resource, options)

    failure_message_for_should do
      "expected\n\n#{actual}\n\nto equal\n\n#{expected}"
    end

    actual == expected
  end

  def parse(body)
    MultiJson.decode(body)
  end
end

RSpec::Matchers.define :deliver_result_image_for do |name|
  match do |response|
    actual = files.detect do |(name, content)|
      response.body.force_encoding('ascii') == content.force_encoding('ascii') # TODO ummmmmmmm?
    end
    actual = actual && actual[0]

    failure_message_for_should do
      "expected #{actual.inspect} to equal #{name.inspect}"
    end

    actual == name
  end

  def files
    files = Hash[*Dir['public/images/result/*.png'].map do |file|
      [File.basename(file, '.png'), File.read(file)]
    end.flatten]
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
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with :transaction
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
