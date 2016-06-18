describe Travis::Api::App::Endpoint, set_app: true do
  class MyEndpoint < Travis::Api::App::Endpoint
    set :prefix, '/my_endpoint'
    get('/') { 'ok' }
  end

  it 'sets up endpoints automatically under given prefix' do
    get('/my_endpoint/').should be_ok
    body.should == "ok"
  end

  it 'does not require a trailing slash' do
    get('/my_endpoint').should be_ok
    body.should == "ok"
  end
end
