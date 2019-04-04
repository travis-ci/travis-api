describe Travis::Api::App::Endpoint, set_app: true do
  let(:token) { Travis::Api::App::AccessToken.create(user: User.last, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }

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

  context 'without forcing authentication' do
    it 'allows access' do
      get '/my_endpoint'
      expect(last_response.status).to eq 200
    end
  end

  context 'when forcing authentication' do
    before { Travis.config.force_authentication = true }
    after { Travis.config.force_authentication = false }

    it 'does not allow access' do
      get '/my_endpoint'
      expect(last_response.status).to eq 403
    end

    it 'does allow access when authenticated' do
      get '/my_endpoint', {}, auth_headers
      expect(last_response.status).to eq 200
    end
  end
end
