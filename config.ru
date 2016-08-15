# Make sure we set that before everything
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || ENV['ENV']
ENV['RAILS_ENV']  = ENV['RACK_ENV']

$stdout.sync = true

require 'travis/api/app'
require 'core_ext/module/load_constants'

models = Travis::Model.constants.map(&:to_s)
only   = [/^(ActiveRecord|ActiveModel|Travis|GH|#{models.join('|')})/]
skip   = ['Travis::Memory', 'GH::ResponseWrapper', 'Travis::Helpers::Legacy', 'GH::FaradayAdapter::EMSynchrony']

[Travis::Api, Travis, GH].each do |target|
  target.load_constants! :only => only, :skip => skip, :debug => false
end

require 'newrelic_rpm'
NewRelic::Agent.after_fork(force_reconnect: true)

run Travis::Api::App.new
