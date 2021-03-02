describe Travis::Api::App::Endpoint::Users, set_app: true do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  before do
    allow(User).to receive(:find_by_vcs_id).and_return(user)
    allow(User).to receive(:find).and_return(user)
    allow(user).to receive(:github_scopes).and_return(['public_repo', 'user:email'])
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    WebMock.stub_request(:post, 'http://vcsfake.travis-ci.com/users/1/check_scopes')
      .to_return(
        status: 200,
        body: nil,
      )
  end
  it 'needs to be authenticated' do
    expect(get('/users', {}, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01')).not_to be_ok
  end
  it 'replies with the current user' do
    expect(get('/users', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01')).to be_ok
    expect(parsed_body['user']).to eq({
      'id'                 => user.id,
      'login'              => user.login,
      'name'               => user.name,
      'email'              => user.email,
      'gravatar_id'        => user.gravatar_id,
      'avatar_url'         => user.avatar_url,
      'locale'             => user.locale,
      'is_syncing'         => user.is_syncing,
      'created_at'         => user.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'first_logged_in_at' => user.first_logged_in_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'synced_at'          => user.synced_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'correct_scopes'     => true,
      'channels'           => ["private-user-1"],
      "allow_migration"    => false,
      "vcs_type"           => "GithubUser",
    })
  end
  context 'when responding to POST for /users/sync' do
    context 'when sync is in progress' do
      before :each do
        allow(user).to receive(:syncing?).and_return(true)
      end
      it 'returns 409' do
        response = post('/users/sync', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01')
        expect(response.status).to eq(409)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Sync already in progress. Try again later.' })
      end
    end
  end
end
