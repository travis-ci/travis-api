require 'spec_helper'

describe Travis::Api::App::Endpoint::Authorization do
  include Travis::Testing::Stubs

  before do
    add_endpoint '/info' do
      get '/login', scope: :private do
        env['travis.access_token'].user.login
      end
    end

    user.stubs(:github_id).returns(42)
    User.stubs(:find_github_id).returns(user)
    User.stubs(:find).returns(user)

    @original_config = Travis.config.oauth2
    Travis.config.oauth2 = {
      authorization_server: 'https://foobar.com',
      access_token_path: '/access_token_path',
      client_id: 'client-id',
      client_secret: 'client-secret',
      scope: 'public_repo,user:email,new_scope',
      insufficient_access_redirect_url: 'https://travis-ci.org/insufficient_access'
    }
  end

  after do
    Travis.config.oauth2 = @original_config
  end

  describe 'GET /auth/authorize' do
    skip "not yet implemented"
  end

  describe 'POST /auth/access_token' do
    skip "not yet implemented"
  end

  describe "GET /auth/handshake" do
    describe 'evil hackers messing with the state' do
      it 'does not succeed if state cookie mismatches' do
        Travis.redis.sadd('github:states', 'github-state')
        response = get '/auth/handshake?state=github-state&code=oauth-code'
        response.status.should be == 400
        response.body.should be == "state mismatch"
        Travis.redis.srem('github:states', 'github-state')
      end
    end

    describe 'with insufficient oauth permissions' do
      before do
        Travis.redis.sadd('github:states', 'github-state')
        rack_mock_session.cookie_jar['travis.state'] = 'github-state'

        response = mock('response')
        response.expects(:body).returns('access_token=foobarbaz-token')
        Faraday.expects(:post).with('https://foobar.com/access_token_path',
                                    client_id: 'client-id',
                                    client_secret: 'client-secret',
                                    scope: 'public_repo,user:email,new_scope',
                                    redirect_uri: 'http://example.org/auth/handshake',
                                    state: 'github-state',
                                    code: 'oauth-code').returns(response)

        data = { 'id' => 111 }
        data.expects(:headers).returns('x-oauth-scopes' => 'public_repo,user:email')
        GH.expects(:with).with(token: 'foobarbaz-token', client_id: nil).returns(data)
      end

      after do
        Travis.redis.srem('github:states', 'github-state')
        # this is cached after first run, so if we change scopes, it will stay
        # like that for the rest of the run
        User::Oauth.instance_variable_set("@wanted_scopes", nil)
      end

      # in endpoint/authorization.rb 271, get_token faraday raises the exception:
      # hostname "foobar.com" does not match the server certificate
      it 'redirects to insufficient access page' do
        response = get '/auth/handshake?state=github-state&code=oauth-code'
        response.should redirect_to('https://travis-ci.org/insufficient_access')
      end

      it 'redirects to insufficient access page for existing user' do
        user = mock('user')
        User.expects(:find_by_github_id).with(111).returns(user)
        expect {
          response = get '/auth/handshake?state=github-state&code=oauth-code'
          response.should redirect_to('https://travis-ci.org/insufficient_access#existing-user')
        }.to_not change { User.count }
      end
    end
  end

  describe 'POST /auth/github' do
    before do
      data = { 'id' => user.github_id, 'name' => user.name, 'login' => user.login, 'gravatar_id' => user.gravatar_id }
      GH.stubs(:with).with(token: 'private repos', client_id: nil).returns stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'repo'}, :to_hash => data)
      GH.stubs(:with).with(token: 'public repos', client_id: nil).returns  stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'public_repo'}, :to_hash => data)
      GH.stubs(:with).with(token: 'no repos', client_id: nil).returns      stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'user'}, :to_hash => data)
      GH.stubs(:with).with(token: 'invalid token', client_id: nil).raises(Faraday::Error::ClientError, 'CLIENT ERROR!')
    end

    def get_token(github_token)
      post('/auth/github', github_token: github_token).should be_ok
      parsed_body['access_token']
    end

    def user_for(github_token)
      get '/info/login', access_token: get_token(github_token)
      last_response.status.should == 200
      user if user.login == body
    end

    it 'accepts tokens with repo scope' do
      user_for('private repos').name.should == user.name
    end

    it 'accepts tokens with public_repo scope' do
      user_for('public repos').name.should == user.name
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', github_token: 'no repos').should_not be_ok
      body.should_not include('access_token')
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', github_token: 'invalid token').should_not be_ok
      body.should_not include('access_token')
    end

    it 'does not store the token' do
      user_for('public repos').github_oauth_token.should_not == 'public repos'
    end

    it "errors if no token is given" do
      post("/auth/github").should_not be_ok
      last_response.status.should == 422
      body.should_not include("access_token")
    end
  end
end
