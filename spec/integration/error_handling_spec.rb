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
    Travis.config.sentry.dsn = 'https://fake:token@app.getsentry.com/12345'
    Travis::Api::App.setup_monitoring
    Travis.testing = false
  end

  after do
    Travis.testing = true
  end

  it 'raises an error in testing mode' do
    begin
      Travis.testing = false

      error = TestError.new('a test error')
      Travis::Api::App::Endpoint::Repos.any_instance.stubs(:service).raises(error)
      res = get '/repos/1', nil, 'HTTP_X_REQUEST_ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975'
    rescue TestError => e
      e.message.should == 'a test error'
    ensure
      Travis.testing = true
    end
  end

  it 'enques error into a thread' do
    error = TestError.new('Konstantin broke all the thingz!')
    Travis::Api::App::Endpoint::Repos.any_instance.stubs(:service).raises(error)
    Raven.expects(:send_event).with do |event|
      event['logentry']['message'] == "#{error.class}: #{error.message}"
    end
    res = get '/repos/1'
    expect(res.status).to eq(500)
    expect(res.body).to eq("Sorry, we experienced an error.\n")
    expect(res.headers).to eq({
      'Content-Type' => 'text/plain',
      'Content-Length' => '32',
    })
    sleep 0.1
  end

  it 'returns request_id in body' do
    error = TestError.new('Konstantin broke all the thingz!')
    Travis::Api::App::Endpoint::Repos.any_instance.stubs(:service).raises(error)
    Raven.stubs(:send_event)
    res = get '/repos/1', nil, 'HTTP_X_REQUEST_ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975'
    expect(res.status).to eq(500)
    expect(res.body).to eq("Sorry, we experienced an error.\n\nrequest_id=235dd08f-10d5-4fcc-9a4d-6b8e6a24f975\n")
    expect(res.headers).to eq({
      'Content-Type' => 'text/plain',
      'Content-Length' => '81',
      'X-Request-ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975',
    })
    sleep 0.1
  end
end
