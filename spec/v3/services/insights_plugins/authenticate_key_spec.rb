describe Travis::API::V3::Services::InsightsPlugins::AuthenticateKey, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/insights_plugins/authenticate_key')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:key_data) { { 'public_id' => 'id', 'private_key' => 'key' } }
    let(:expected_json) do
      {
        "@type" => "insights_plugin_authenticate",
        "success" => true,
        "error_msg" => ""
      }
    end

    before do
      stub_insights_request(:post, '/user_plugins/authenticate_key', auth_key: insights_auth_key, user_id: user.id)
        .with(body: JSON.dump(key_data))
        .to_return(status: 201, body: JSON.dump(insights_authenticate_key_response))
    end

    it 'responds with authenticate result' do
      post('/v3/insights_plugins/authenticate_key', key_data, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
