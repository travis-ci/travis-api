# Make sure we set that before everything
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || ENV['ENV']
ENV['RAILS_ENV']  = ENV['RACK_ENV']

$stdout.sync = true

require 'travis/api/app'
require 'core_ext/module/load_constants'

[Travis::Api, Travis, GH].each do |target|
  target.load_constants!(:only => [/^Travis/, /^GH/], :skip => ['Travis::Memory', 'GH::ResponseWrapper'], :debug => true)
end

run Travis::Api::App.new
