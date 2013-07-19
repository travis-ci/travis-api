# Make sure we set that before everything
ENV['RACK_ENV'] ||= ENV['RAILS_ENV'] || ENV['ENV']
ENV['RAILS_ENV']  = ENV['RACK_ENV']

$stdout.sync = true

require 'travis/api/app'
require 'core_ext/module/load_constants'

models = Travis::Model.constants.map(&:to_s)
only   = [/^(ActiveRecord|ActiveModel|Travis|GH|#{models.join('|')})/]
skip   = ['Travis::Memory', 'GH::ResponseWrapper', 'Travis::NewRelic']

[Travis::Api, Travis, GH].each do |target|
  target.load_constants! :only => only, :skip => skip, :debug => false
end

# https://help.heroku.com/tickets/92756
class RackTimer
  def initialize(app)
    @app = app
  end

  def call(env)
    start_request = Time.now
    status, headers, body = @app.call(env)
    elapsed = (Time.now - start_request) * 1000
    $stdout.puts("request-id=#{env['HTTP_HEROKU_REQUEST_ID']} measure.rack-request=#{elapsed.round}ms")
    [status, headers, body]
  end
end

use RackTimer
run Travis::Api::App.new
