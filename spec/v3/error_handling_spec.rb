describe Travis::API::V3::ServiceIndex, set_app: true do
  let(:headers) {{  }}
  let(:path)      { "/v3/repo/1/enable"         }
  let(:json)      { JSON.load(response.body) }
  let(:response)  { get(path, {}, headers)   }
  let(:resources) { json.fetch('resources')  }

  it "handles wrong HTTP method with 405 status" do
    response.status.should == 405
  end
end

describe Travis::API::V3::Router, set_app: true do
  include Rack::Test::Methods

  class TestError < StandardError; end

  before do
    set_app Raven::Rack.new(app)
    Travis.config.sentry.dsn = "test"
    Travis::Api::App.setup_monitoring
  end

  it 'Sentry captures router errors' do
    error = TestError.new('Konstantin broke all the thingz!')
    Travis::API::V3::Models::Repository.any_instance.stubs(:service).raises(error)
    Raven.expects(:send_event).with do |event|
      event.message == "#{error.class}: #{error.message}"
    end
    expect { get "/v3/repo/1" }.to raise_error(TestError)
    sleep 0.1
  end
end
