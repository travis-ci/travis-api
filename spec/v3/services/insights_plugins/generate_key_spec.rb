describe Travis::API::V3::Services::InsightsPlugins::GenerateKey, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/insights_plugins/generate_key')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:plugin_name) { 'name' }
    let(:plugin_type) { 'type' }
    let(:expected_json) do
      {
        "@type" => "insights_plugin_key",
        "keys" => [
          "TIDE0C7A9C1D5E",
          "a8f702e9363e8573dd476c116e62cf6e04e44c8610dc939c67e45777f2b6cbdb"
        ]
      }
    end

    before do
      stub_insights_request(:get, '/user_plugins/generate_key', query: { name: plugin_name, plugin_type: plugin_type }.to_query, auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_generate_key_response))
    end

    it 'responds with list of subscriptions' do
      get("/v3/insights_plugins/generate_key?plugin_name=#{plugin_name}&plugin_type=#{plugin_type}", {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
