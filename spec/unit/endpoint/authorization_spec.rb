describe Travis::Api::App::Endpoint::Authorization, billing_spec_helper: true do
  include Travis::Testing::Stubs

  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }
  let(:vcs_url) { 'http://vcsfake.travis-ci.com' }

  before do
    add_endpoint '/info' do
      get '/login', scope: :private do
        env['travis.access_token'].user.login
      end
    end

    allow(user).to receive(:vcs_id).and_return(42)
    allow(User).to receive(:find).and_return(user)

    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
    Travis.config.vcs.url = vcs_url
    Travis.config.vcs.token = 'vcs-token'
    WebMock.stub_request(:post, 'http://billingfake.travis-ci.com/v2/initial_subscription')
           .to_return(status: 200, body: JSON.dump(billing_v2_subscription_response_body('id' => 456, 'owner' => { 'type' => 'User', 'id' => user.id })))
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
              'User-Agent' => 'Faraday v0.17.3'
            }).
          to_return(status: 200, body: "", headers: {})
      end

      it 'does not succeed if state cookie mismatches (redirects)' do
        Travis.redis.sadd('github:states', 'github-state')
        response = get('/auth/handshake?state=github-state&code=oauth-code')
        expect(response.status).to eq(302)
        Travis.redis.srem('github:states', 'github-state')
      end
    end

    describe 'On com and enterprise, evil hackers messing with redirection' do
      before do
        WebMock.stub_request(:post, 'http://vcsfake.travis-ci.com/users/session?code=1234&provider=github&redirect_uri=http://example.org/auth/handshake/github')
          .to_return(
            status: 200,
            body: JSON.dump(
              data: {
                user: {
                  id: user.id,
                }
              }
            ),
          )

        WebMock.stub_request(:post, 'http://vcsfake.travis-ci.com/users/1/check_scopes')
          .to_return(
            status: 200,
            body: nil,
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

        it 'does allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{URI.encode(state)}"
          expect(response.status).to eq(200)
        end
      end

      context 'when redirect uri is not allowed' do
        let(:state) { 'github-state:::https://dark-corner-of-web.com/' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{URI.encode(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when script tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<sCrIpt' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{URI.encode(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
      end

      context 'when onerror tag is injected into redirect uri' do
        let(:state) { 'github-state:::https://travis-ci.com/<img% src="" onerror="badcode()"' }

        it 'does not allow redirect' do
          response = get "/auth/handshake/github?code=1234&state=#{URI.encode(state)}"
          expect(response.status).to eq(401)
          expect(response.body).to eq("target URI not allowed")
        end
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
        expect(User).to receive(:find_by_vcs_id).with(111).and_return(user)
        expect {
          response = get '/auth/handshake?state=github-state&code=oauth-code'
          expect(response).to redirect_to('https://travis-ci.org/insufficient_access#existing-user')
        }.to_not change { User.count }
      end
    end
  end

  describe 'POST /auth/github' do
    let(:token) { 'private repos' }
    let(:access_token) { 'access_123' }
    let(:user_data) do
      { 'id' => user.vcs_id, 'name' => user.name, 'login' => user.login, 'gravatar_id' => user.gravatar_id }
    end

    before do
      WebMock.stub_request(:post, "http://vcsfake.travis-ci.com/users/session/generate_token?app_id=1&provider=github&token=#{CGI.escape(token)}").
        to_return(
          status: 200,
          body: JSON.dump(
            data: {
              user: user_data,
              token: access_token,
            },
          ),
        )
    end

    def get_token(github_token)
      expect(post('/auth/github', github_token: github_token)).to be_ok
      parsed_body['access_token']
    end

    it 'returns an access token' do
      expect(get_token(token)).to eq(access_token)
    end

    it "errors if no token is given" do
      allow(User).to receive(:find_by_vcs_id).with(111).and_return(user)
      expect(post("/auth/github")).not_to be_ok
      expect(last_response.status).to eq(422)
      expect(body).not_to include("access_token")
    end
  end
end
