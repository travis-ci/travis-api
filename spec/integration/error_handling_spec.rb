require 'sentry-raven'

describe 'Exception', set_app: true do
  class FixRaven < Struct.new(:app)
    def call(env)
      requested_at = env['requested_at']
      env['requested_at'] = env['requested_at'].to_s if env.key?('requested_at')
      app.call(env)
    rescue Exception => e
      env['requested_at'] = requested_at
      raise e
    end
  end

  class TestError < StandardError
  end

  before do
    set_app Raven::Rack.new(FixRaven.new(app))
    Travis.config.sentry.dsn = "test"
    Travis::Api::App.setup_monitoring
  end

  it 'enques error into a thread' do
    error = TestError.new('Konstantin broke all the thingz!')
    Travis::Api::App::Endpoint::Repos.any_instance.stubs(:service).raises(error)
    Raven.expects(:send_event).with do |event|
      event.message == "#{error.class}: #{error.message}"
    end
    expect { get "/repos" }.to raise_error(TestError)
    sleep 0.1
  end
end
