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

  it 'does not check auth' do
    expect(subject.settings.check_auth?).to eq false
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
        response = get '/auth/handshake?state=vcs-state&code=oauth-code'
        response.status.should be == 400
        response.body.should be == "state mismatch"
      end
    end

    describe 'with insufficient oauth permissions' do
      before do
        Travis.redis.sadd('vcs:states', 'vcs-state')
        rack_mock_session.cookie_jar['travis.state'] = 'vcs-state'

        response = mock('response')
        response.expects(:body).returns('access_token=foobarbaz-token')
        Faraday.expects(:post).with('https://foobar.com/access_token_path',
                                    client_id: 'client-id',
                                    client_secret: 'client-secret',
                                    scope: 'public_repo,user:email,new_scope',
                                    redirect_uri: 'http://example.org/auth/handshake',
                                    state: 'vcs-state',
                                    code: 'oauth-code').returns(response)

        data = { 'id' => 111 }
        data.expects(:headers).returns('x-oauth-scopes' => 'public_repo,user:email')
        GH.expects(:with).with(token: 'foobarbaz-token', client_id: nil).returns(data)
      end

      after do
        Travis.redis.srem('vcs:states', 'vcs-state')
      end

      # in endpoint/authorization.rb 271, get_token faraday raises the exception:
      # hostname "foobar.com" does not match the server certificate
      # TODO disabling this as per @rkh's advice
      xit 'redirects to insufficient access page' do
        response = get '/auth/handshake?state=vcs-state&code=oauth-code'
        response.should redirect_to('https://travis-ci.org/insufficient_access')
      end

      # TODO disabling this as per @rkh's advice
      xit 'redirects to insufficient access page for existing user' do
        user = mock('user')
        User.expects(:find_by_github_id).with(111).returns(user)
        expect {
          response = get '/auth/handshake?state=vcs-state&code=oauth-code'
          response.should redirect_to('https://travis-ci.org/insufficient_access#existing-user')
        }.to_not change { User.count }
      end
    end
  end

  describe 'POST /auth/github' do
    let(:token) { 'token' }
    let(:github_token) { '123' }

    subject { post('/auth/github', github_token: github_token) }

    before do
      ::Travis::RemoteVCS::User.any_instance.stubs(:generate_token).returns('token' => token)
    end

    it 'calls vcs service' do
      expect(JSON.parse(subject.body)['access_token']).to eq(token)
    end
  end
end
