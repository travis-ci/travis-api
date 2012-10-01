ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'travis/api/app'
require 'sinatra/test_helpers'
require 'logger'
require 'gh'
require 'multi_json'
require 'debugger'

Travis.logger = Logger.new(StringIO.new)
Travis::Api::App.setup

Backports.require_relative_dir 'support'

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

RSpec.configure do |config|
  config.mock_framework = :mocha
  config.expect_with :rspec, :stdlib
  config.include TestHelpers

  config.before :each do
    ::Redis.connect(url: Travis.config.redis.url).flushdb
    set_app Travis::Api::App.new
  end

  config.after :each do
    custom_endpoints.each do |endpoint|
      endpoint.superclass.direct_subclasses.delete(endpoint)
    end
  end
end
