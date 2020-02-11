describe Travis::Api::App::Middleware::ScopeCheck do
  include Travis::Testing::Stubs

  let :access_token do
    Travis::Api::App::AccessToken.create(user: user, scope: :foo, app_id: -1)
  end

  before do
    mock_app do
      use Travis::Api::App::Middleware::ScopeCheck
      get('/') { 'ok' }
      get('/token') { env['travis.access_token'].to_s }
    end

    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  it 'lets through requests without a token' do
    expect(get('/')).to be_ok
    expect(body).to eq('ok')
    expect(headers['X-OAuth-Scopes']).not_to eq('foo')
  end

  describe 'sets associated scope properly' do
    it 'accepts Authorization token header' do
      expect(get('/', {}, 'HTTP_AUTHORIZATION' => "token #{access_token}")).to be_ok
      expect(headers['X-OAuth-Scopes']).to eq('foo')
    end

    it 'accepts basic auth' do
      authorize access_token.to_s, 'x'
      expect(get('/')).to be_ok
      expect(headers['X-OAuth-Scopes']).to eq('foo')
    end

    it 'accepts query parameters' do
      expect(get('/', access_token: access_token.to_s)).to be_ok
      expect(headers['X-OAuth-Scopes']).to eq('foo')
    end
  end

  describe 'with travis token' do
    let(:travis_token) { stub_travis_token(user: user) }
    let(:token) { travis_token.token }

    before do
      allow(Token).to receive(:find_by_token).with(travis_token.token).and_return(travis_token)
      allow(Token).to receive(:find_by_token).with("invalid").and_return(nil)
    end

    it 'accepts a valid travis token' do
      expect(get('/', token: token)).to be_ok
    end

    it 'rejects an invalid travis token' do
      get('/', token: token)
      expect(headers['X-OAuth-Scopes']).to eq('travis_token')
    end

    it 'sets the scope to travis_token' do
      expect(get('/', token: "invalid")).not_to be_ok
    end
  end

  describe 'reject requests with an invalid token' do
    it 'rejects Authorization token header' do
      expect(get('/', {}, 'HTTP_AUTHORIZATION' => "token foo")).not_to be_ok
    end

    it 'rejects basic auth' do
      authorize 'foo', 'x'
      expect(get('/')).not_to be_ok
    end

    it 'rejects query parameters' do
      expect(get('/', access_token: 'foo')).not_to be_ok
    end
  end

  it 'sets env["travis.access_token"]' do
    authorize access_token.to_s, 'x'
    expect(get('/token').body).to eq(access_token.to_s)
  end
end
