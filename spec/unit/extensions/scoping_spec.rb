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

    User.stubs(:find).with(user.id).returns(user)
  end

  def with_scopes(url, *scopes)
    token = Travis::Api::App::AccessToken.create(user: user, scopes: scopes, app_id: -1)
    get(url, {}, 'travis.access_token' => token)
  end

  it 'uses the default scope if no token is given' do
    get('/').should be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'public'
    headers['X-OAuth-Scopes'].should == 'public'
  end

  it 'allows overriding scopes for anonymous users' do
    settings.set anonymous_scopes: [:foo]
    get('/').should_not be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'public'
    headers['X-OAuth-Scopes'].should == 'foo'
  end

  it 'allows overriding default scope' do
    settings.set default_scope: :foo
    get('/').should_not be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'foo'
    headers['X-OAuth-Scopes'].should == 'public'
  end

  it 'allows overriding default scope and anonymous scope' do
    settings.set default_scope: :foo, anonymous_scopes: [:foo, :bar]
    get('/').should be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'foo'
    headers['X-OAuth-Scopes'].should == 'foo,bar'
  end

  it 'takes the scope from the access token' do
    with_scopes('/', :foo).should_not be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'public'
    headers['X-OAuth-Scopes'].should == 'foo'
  end

  it 'accepts the scope from the condition' do
    with_scopes('/private', :foo, :bar, :private).should be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'private'
    headers['X-OAuth-Scopes'].should == 'foo,bar,private'
  end

  it 'rejects if scope from condition is missing' do
    with_scopes('/private', :foo, :bar).should_not be_ok
    headers['X-Accepted-OAuth-Scopes'].should == 'private'
    headers['X-OAuth-Scopes'].should == 'foo,bar'
  end

  it 'passes on to unscoped routes' do
    get('/pass_me').should be_ok
    body.should == 'second'
  end


  it 'does not pass if scope matches' do
    with_scopes('/pass_me', :private).should be_ok
    body.should == 'first'
  end
end
