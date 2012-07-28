ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['ENV'] = 'test'

require 'rspec'
require 'travis/api/app'
require 'sinatra/test_helpers'
require 'logger'

Travis.logger = Logger.new(StringIO.new)
Travis::Api::App.setup

Backports.require_relative_dir 'support'

RSpec.configure do |config|
  config.expect_with :rspec, :stdlib
  config.include Sinatra::TestHelpers
  config.before(:each) { set_app Travis::Api::App.new }
end
