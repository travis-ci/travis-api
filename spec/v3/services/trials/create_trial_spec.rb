describe Travis::API::V3::Services::Trials::Create, set_app: true, billing_spec_helper: true do
    let(:parsed_body) { JSON.load(last_response.body) }
    let(:billing_url) { 'http://billingfake.travis-ci.com' }
    let(:billing_auth_key) { 'secret' }
  
    before do
      Travis.config.billing.url = billing_url
      Travis.config.billing.auth_key = billing_auth_key
    end
  
    context 'authenticated user' do
      let(:user) { Factory(:user) }
      let(:organization) { Factory(:org, login: 'travis') }
      let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
      let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
      let(:created_at) { '2018-04-17T18:30:32Z' }
      before do
        stub_billing_request(:post, "/trials/user/" + user.id.to_s, auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 202, body: JSON.dump(id: user.id, login: user.login))
        stub_billing_request(:post, "/trials/organization/" + organization.id.to_s, auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 202, body: JSON.dump(id: organization.id, login: organization.login))
        stub_billing_request(:get, '/trials', auth_key: billing_auth_key, user_id: user.id)
          .to_return(status: 200, body: JSON.dump([
            billing_trial_response_body('id' => 123, 'created_at' => created_at, 'builds_remaining' => 6, 'owner' => { 'type' => 'User', 'id' => user.id }),
            billing_trial_response_body('id' => 456, 'created_at' => created_at, 'builds_remaining' => 6, 'owner' => { 'type' => 'Organization', 'id' => organization.id })
          ]))
      end
  
      it 'subscribe user to trial' do
        post("/v3/trials", {owner: user.id, type: 'user'}, headers)
        expect(last_response.status).to eq(202)
        expect(parsed_body).to eql_json({
          '@type' => 'trials',
          '@representation' => 'standard',
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
              'login' => user.login
            },
            'created_at' => created_at,
            'status' => 'started',
            'builds_remaining' => 6
          }]
        })
      end

      it 'subscribe organization to trial' do
        post("/v3/trials", {owner: organization.id, type: 'organization'}, headers)
        expect(last_response.status).to eq(202)
        expect(parsed_body).to eql_json({
          '@type' => 'trials',
          '@representation' => 'standard',
          'trials' => [{
            '@type' => 'trial',
            '@representation' => 'standard',
            '@permissions' => {
              'read' => true,
              'write' => true
            },
            'id' => 456,
            'owner' => {
              '@type' => 'organization',
              '@href' => "/v3/org/#{organization.id}",
              '@representation' => 'minimal',
              'id' => organization.id,
              'login' => organization.login
            },
            'created_at' => created_at,
            'status' => 'started',
            'builds_remaining' => 6
          }]
        })
      end
    end
  end
  