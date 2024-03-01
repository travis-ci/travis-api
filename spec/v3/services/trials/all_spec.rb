describe Travis::API::V3::Services::Trials::All, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/trials')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:organization) { FactoryBot.create(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:created_at) { '2018-04-17T18:30:32Z' }
    before do
      stub_billing_request(:get, '/trials', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: [billing_trial_response_body('id' => 123, 'created_at' => created_at, 'builds_remaining' => 6, 'owner' => { 'type' => 'User', 'id' => user.id })])
    end

    it 'responds with list of trials' do
      get('/v3/trials', {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'trials',
        '@representation' => 'standard',
        '@href' => '/v3/trials',
        'trials' => [{
          '@type' => 'trial',
          '@representation' => 'standard',
          '@permissions' => {
            'read' => true,
            'write' => true
          },
          'id' => 123,
          'owner' => {
            '@type' => 'user',
            '@href' => "/v3/user/#{user.id}",
            '@representation' => 'minimal',
            'id' => user.id,
            'login' => 'svenfuchs',
            'vcs_type' => 'GithubUser',
            'name' => user.name,
            'ro_mode' => true
          },
          'created_at' => created_at,
          'status' => 'started',
          'builds_remaining' => 6
        }]
      })
    end
  end
end
