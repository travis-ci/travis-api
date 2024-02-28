describe Travis::Api::App::Endpoint::Authorization, billing_spec_helper: true do
  include Travis::Testing::Stubs

  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  before { allow_any_instance_of(Travis::RemoteVCS::User).to receive(:check_scopes) }

  before do
    add_endpoint '/info' do
      get '/login', scope: :private do
        env['travis.access_token'].user.login
      end
    end

    allow(user).to receive(:github_id).and_return(42)
    allow(User).to receive(:find_github_id).and_return(user)
    allow(User).to receive(:find).and_return(user)

    @original_config = Travis.config.oauth2
    Travis.config.oauth2 = {
      authorization_server: 'https://foobar.com',
      access_token_path: '/access_token_path',
      client_id: 'client-id',
      client_secret: 'client-secret',
      scope: 'public_repo,user:email,new_scope',
      insufficient_access_redirect_url: 'https://travis-ci.org/insufficient_access'
    }
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
    WebMock.stub_request(:post, 'http://billingfake.travis-ci.com/v2/initial_subscription')
           .to_return(status: 200, body: JSON.dump(billing_v2_subscription_response_body('id' => 456, 'owner' => { 'type' => 'User', 'id' => user.id })))
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
    before do
      ENV['TRAVIS_SITE'] = 'org'
    end
    after do
      ENV['TRAVIS_SITE'] = nil
    end

    describe 'evil hackers messing with the state' do
      before do
        WebMock.stub_request(:post, "https://foobar.com/access_token_path").
          with(
            body: "{\"client_id\":\"client-id\",\"scope\":\"public_repo,user:email,new_scope\",\"redirect_uri\":\"http://example.org/auth/handshake\",\"state\":\"github-state\",\"code\":\"oauth-code\",\"client_secret\":\"client-secret\"}",
            headers: {
              'Accept' => '*/*',
              'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
              'Connection' => 'keep-alive',
              'Content-Type' => 'application/json',
              'Keep-Alive' => '30',
              'User-Agent' => 'Faraday v2.7.10'
            }).
          to_return(status: 200, body: "", headers: {})
      end

      it 'does not succeed if state cookie mismatches (redirects)' do
        Travis.redis.sadd('github:states', 'github-state')
        response = get '/auth/handshake?state=github-state&code=oauth-code'
        expect(response.status).to eq(302)
        Travis.redis.srem('github:states', 'github-state')
      end
    end

    describe 'On org, evil hackers messing with redirection' do
      before do
        WebMock.stub_request(:post, "https://foobar.com/access_token_path")
          .to_return(status: 200, body: 'access_token=token&token_type=bearer')

        WebMock.stub_request(:get, "https://api.github.com/user?per_page=100")
          .to_return(
            status: 200,
            body: JSON.dump(name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', id: 456, foo: 'bar'), headers: {'X-OAuth-Scopes' => 'repo, user, new_scope'}
          )

          WebMock.stub_request(:head, "https://api.github.com/user")
          .to_return(
            status: 200,
          )


        cookie_jar['travis.state-github'] = state
        Travis.redis.sadd('github:states', state)
      end

      after do
        Travis.redis.srem('github:states', state)
      end

      context 'when redirect uri is correct' do
        let(:state) { 'github-state:::https://travis-ci.com/?any=params' }

        it 'it does allow redirect' do
          response = get "/auth/handshake?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(200)
        end
      end

      context 'when redirect uri is not allowed' do
        let(:state) { 'github-state:::https://dark-corner-of-web.com/' }

        it 'does not allow redirect' do
          response = get "/auth/handshake?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when script tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<sCrIpt' }

        it 'does not allow redirect' do
          response = get "/auth/handshake?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when onerror tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<img% src="" onerror="badcode()"' }

        it 'does not allow redirect' do
          response = get "/auth/handshake?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end
    end

    describe 'On com and enterprise, evil hackers messing with redirection' do
      before do
        WebMock.stub_request(:post, "https://foobar.com/access_token_path")
          .to_return(status: 200, body: 'access_token=token&token_type=bearer')

        WebMock.stub_request(:get, "https://api.github.com/user?per_page=100")
          .to_return(
            status: 200,
            body: JSON.dump(name: 'Piotr Sarnacki', login: 'drogus', gravatar_id: '123', id: 456, foo: 'bar'), headers: {'X-OAuth-Scopes' => 'repo, user, new_scope'}
          )

        WebMock.stub_request(:head, "https://api.github.com/user")
          .to_return(
            status: 200,
          )


        cookie_jar['travis.state-github'] = state
        Travis.redis.sadd('github:states', state)
        ENV['TRAVIS_SITE'] = nil
      end

      after do
        Travis.redis.srem('github:states', state)
      end

      context 'when redirect uri is correct' do
        let(:state) { 'github-state:::https://travis-ci.com/?any=params' }

        it 'it does allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(200)
        end
      end

      context 'when redirect uri is not allowed' do
        let(:state) { 'github-state:::https://dark-corner-of-web.com/' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when script tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<sCrIpt' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when onerror tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<img% src="" onerror="badcode()"' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{CGI.escape(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end
    end
    
    describe 'when cluster param is passed' do
      let(:user) { FactoryBot.create :user }
      let(:cluster) { 'awscluster' }

      before do
        ENV['TRAVIS_SITE'] = 'com'
        cookie_jar['travis.state-assembla'] = state
        Travis.redis.sadd('github:states', state)
        WebMock.stub_request(:post, /\/users\/session\?cluster=#{cluster}&code=1234&provider=assembla&redirect_uri=http:\/\/example.org\/auth\/handshake\/assembla/)
          .to_return(status: 200, body: JSON.dump(data: { user: { id: '1' } }))
      end
      
      after do
        ENV['TRAVIS_SITE'] = nil
      end
      
      let(:state) { '1234' }

      it 'passes the cluster param' do
        response = get "/auth/handshake/assembla?code=1234&state=#{CGI.escape(state)}&cluster=#{cluster}"

        expect(response.status).to eq(302)
      end
    end

    describe 'with insufficient oauth permissions' do
      before do
        Travis.redis.sadd('github:states', 'github-state')
        rack_mock_session.cookie_jar['travis.state'] = 'github-state'

        response = double('response')
        expect(response).to receive(:body).and_return('access_token=foobarbaz-token')
        expect(Faraday).to receive(:post).with('https://foobar.com/access_token_path',
                                    client_id: 'client-id',
                                    client_secret: 'client-secret',
                                    scope: 'public_repo,user:email,new_scope',
                                    redirect_uri: 'http://example.org/auth/handshake',
                                    state: 'github-state',
                                    code: 'oauth-code').and_return(response)

        data = { 'id' => 111 }
        expect(data).to receive(:headers).and_return('x-oauth-scopes' => 'public_repo,user:email')
        expect(GH).to receive(:with).with(token: 'foobarbaz-token', client_id: nil).and_return(data)
      end

      after do
        Travis.redis.srem('github:states', 'github-state')
      end

      # in endpoint/authorization.rb 271, get_token faraday raises the exception:
      # hostname "foobar.com" does not match the server certificate
      # TODO disabling this as per @rkh's advice
      xit 'redirects to insufficient access page' do
        response = get '/auth/handshake?state=github-state&code=oauth-code'
        expect(response).to redirect_to('https://travis-ci.org/insufficient_access')
      end

      # TODO disabling this as per @rkh's advice
      xit 'redirects to insufficient access page for existing user' do
        user = double('user')
        expect(User).to receive(:find_by_github_id).with(111).and_return(user)
        expect {
          response = get '/auth/handshake?state=github-state&code=oauth-code'
          expect(response).to redirect_to('https://travis-ci.org/insufficient_access#existing-user')
        }.to_not change { User.count }
      end
    end
  end

  describe 'POST /auth/github' do
    before do
      data = { 'id' => user.github_id, 'name' => user.name, 'login' => user.login, 'gravatar_id' => user.gravatar_id }
      allow(GH).to receive(:with).with(token: 'private repos', client_id: nil).and_return double(:[] => user.login, :headers => {'x-oauth-scopes' => 'repo'}, :to_hash => data)
      allow(GH).to receive(:with).with(token: 'public repos', client_id: nil).and_return  double(:[] => user.login, :headers => {'x-oauth-scopes' => 'public_repo'}, :to_hash => data)
      allow(GH).to receive(:with).with(token: 'no repos', client_id: nil).and_return      double(:[] => user.login, :headers => {'x-oauth-scopes' => 'user'}, :to_hash => data)
      allow(GH).to receive(:with).with(token: 'invalid token', client_id: nil).and_raise(Faraday::ClientError, 'CLIENT ERROR!')
    end

    def get_token(github_token)
      expect(post('/auth/github', github_token: github_token)).to be_ok
      parsed_body['access_token']
    end

    def user_for(github_token)
      get '/info/login', access_token: get_token(github_token)
      expect(last_response.status).to eq(200)
      user if user.login == body
    end

    it 'accepts tokens with repo scope' do
      expect(user_for('private repos').name).to eq(user.name)
    end

    it 'accepts tokens with public_repo scope' do
      expect(user_for('public repos').name).to eq(user.name)
    end

    it 'rejects tokens with user scope' do
      expect(post('/auth/github', github_token: 'no repos')).not_to be_ok
      expect(body).not_to include('access_token')
    end

    it 'rejects tokens with user scope' do
      expect(post('/auth/github', github_token: 'invalid token')).not_to be_ok
      expect(body).not_to include('access_token')
    end

    it 'does not store the token' do
      expect(user_for('public repos').github_oauth_token).not_to eq('public repos')
    end

    it "errors if no token is given" do
      allow(User).to receive(:find_by_github_id).with(111).and_return(user)
      expect(post("/auth/github")).not_to be_ok
      expect(last_response.status).to eq(422)
      expect(body).not_to include("access_token")
    end

    it "errors if github throws an error" do
      allow(GH).to receive(:with).and_raise(GH::Error)
      expect(post("/auth/github", github_token: 'foo bar')).not_to be_ok
      expect(last_response.status).to eq(403)
      expect(body).not_to include("access_token")
      expect(body).to include("not a Travis user")
    end

    it 'syncs the user' do
      expect(Travis).to receive(:run_service).with(:sync_user, instance_of(User))
      expect(post('/auth/github', github_token: 'public repos')).to be_ok
    end
  end

  describe 'GET /confirm_user/:token' do
    context 'when response is ok' do
      before { allow_any_instance_of(Travis::RemoteVCS::User).to receive(:confirm_user) }

      it 'returns ok' do
        expect(get('/auth/confirm_user/mytokentopass')).to be_ok
      end

      it 'calls VCS service with proper params' do
        expect_any_instance_of(Travis::RemoteVCS::User)
          .to receive(:confirm_user).with(token: 'mytokentopass')

        get('/auth/confirm_user/mytokentopass')
      end
    end

    context 'when response is not ok' do
      before do
        allow_any_instance_of(Travis::RemoteVCS::User)
          .to receive(:confirm_user).and_raise(Travis::RemoteVCS::ResponseError)
      end

      it 'returns 404 with a message' do
        expect(get('/auth/confirm_user/mytokentopass')).not_to be_ok
        expect(last_response.status).to eq(404)
        expect(body).to include('The token is expired or not found.')
      end
    end
  end

  describe 'GET /request_confirmation/:session_token/:id' do
    let(:current_user) { double(:user, id: 123) }
    before do
      allow_any_instance_of(described_class).to receive(:current_user).and_return(current_user)
      allow_any_instance_of(Travis::RemoteVCS::User).to receive(:request_confirmation)
    end

    it 'returns ok' do
      expect(get('/auth/request_confirmation/123')).to be_ok
    end

    it 'calls VCS service with proper params' do
      expect_any_instance_of(Travis::RemoteVCS::User)
        .to receive(:request_confirmation).with(id: 123)

      get('/auth/request_confirmation/123')
    end
  end
end
