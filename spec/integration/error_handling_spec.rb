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
    Raven.configure do |config|
      config.silence_ready = true
    end

    set_app Raven::Rack.new(FixRaven.new(app))
    Travis.config.sentry.dsn = 'https://fake:token@app.getsentry.com/12345'
    Travis::Api::App.setup_monitoring
    Travis.testing = false

    allow(Raven).to receive(:send_event)
  end

  after do
    Travis.testing = true
  end

  it 'raises an error in testing mode' do
    begin
      Travis.testing = false

      error = TestError.new('a test error')
      allow_any_instance_of(Travis::Api::App::Endpoint::Repos).to receive(:service).and_raise(error)
      res = get '/repos/1', nil, 'HTTP_X_REQUEST_ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975'
    rescue TestError => e
      expect(e.message).to eq('a test error')
    ensure
      Travis.testing = true
    end
  end

  it 'enqueues error into a thread' do
    error = TestError.new('Konstantin broke all the thingz!')
    allow_any_instance_of(Travis::Api::App::Endpoint::Repos).to receive(:service).and_raise(error)
    expect(Raven).to receive(:send_event).with(
      satisfy { |event| event['logentry']['message'] == "#{error.class}: #{error.message}" }
    )
    res = get '/repos/1'
    expect(res.status).to eq(500)
    expect(res.body).to eq("Sorry, we experienced an error.\n")
    expect(res.headers).to eq({
      'Content-Type' => 'text/plain',
      'Content-Length' => '32',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Expose-Headers' => 'Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID',
    })
    sleep 0.1
  end

  it 'returns request_id in body' do
    error = TestError.new('Konstantin broke all the thingz!')
    allow_any_instance_of(Travis::Api::App::Endpoint::Repos).to receive(:service).and_raise(error)
    allow(Raven).to receive(:send_event)
    res = get '/repos/1', nil, 'HTTP_X_REQUEST_ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975'
    expect(res.status).to eq(500)
    expect(res.body).to eq("Sorry, we experienced an error.\n\nrequest_id:235dd08f-10d5-4fcc-9a4d-6b8e6a24f975\n")
    expect(res.headers).to eq({
      'Content-Type' => 'text/plain',
      'Content-Length' => '81',
      'X-Request-ID' => '235dd08f-10d5-4fcc-9a4d-6b8e6a24f975',
      'Access-Control-Allow-Origin' => '*',
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Expose-Headers' => 'Content-Type, Cache-Control, Expires, Etag, Last-Modified, X-Request-ID',
    })
    sleep 0.1
  end
end
