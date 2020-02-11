describe Travis::Api::App::Extensions::Scoping do
  include Travis::Testing::Stubs

  before do
    mock_app do
      register Travis::Api::App::Extensions::Scoping
      get('/') { 'ok' }
      get('/private', scope: :private) { 'ok' }
      get('/pass_me', scope: :private) { 'first' }
      get('/pass_me') { 'second' }
    end

    allow(User).to receive(:find).with(user.id).and_return(user)
  end

  def with_scopes(url, *scopes)
    token = Travis::Api::App::AccessToken.create(user: user, scopes: scopes, app_id: -1)
    get(url, {}, 'travis.access_token' => token)
  end

  it 'uses the default scope if no token is given' do
    expect(get('/')).to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('public')
    expect(headers['X-OAuth-Scopes']).to eq('public')
  end

  it 'allows overriding scopes for anonymous users' do
    settings.set anonymous_scopes: [:foo]
    expect(get('/')).not_to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('public')
    expect(headers['X-OAuth-Scopes']).to eq('foo')
  end

  it 'allows overriding default scope' do
    settings.set default_scope: :foo
    expect(get('/')).not_to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('foo')
    expect(headers['X-OAuth-Scopes']).to eq('public')
  end

  it 'allows overriding default scope and anonymous scope' do
    settings.set default_scope: :foo, anonymous_scopes: [:foo, :bar]
    expect(get('/')).to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('foo')
    expect(headers['X-OAuth-Scopes']).to eq('foo,bar')
  end

  it 'takes the scope from the access token' do
    expect(with_scopes('/', :foo)).not_to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('public')
    expect(headers['X-OAuth-Scopes']).to eq('foo')
  end

  it 'accepts the scope from the condition' do
    expect(with_scopes('/private', :foo, :bar, :private)).to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('private')
    expect(headers['X-OAuth-Scopes']).to eq('foo,bar,private')
  end

  it 'rejects if scope from condition is missing' do
    expect(with_scopes('/private', :foo, :bar)).not_to be_ok
    expect(headers['X-Accepted-OAuth-Scopes']).to eq('private')
    expect(headers['X-OAuth-Scopes']).to eq('foo,bar')
  end

  it 'passes on to unscoped routes' do
    expect(get('/pass_me')).to be_ok
    expect(body).to eq('second')
  end


  it 'does not pass if scope matches' do
    expect(with_scopes('/pass_me', :private)).to be_ok
    expect(body).to eq('first')
  end
end
