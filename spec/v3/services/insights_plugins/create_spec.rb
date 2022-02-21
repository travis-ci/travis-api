describe Travis::API::V3::Services::InsightsPlugins::Create, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/insights_plugins')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:name) { 'plugin' }
    let(:plugin_data) { { 'name' => name } }
    let(:expected_json) do
      {
        "@type"=>"insights_plugin",
        "@representation"=>"standard",
        "id"=>3,
        "name"=>"plugin",
        "public_id"=>"TI74D0AACAC0BD",
        "plugin_type"=>"Kubernetes Cluster",
        "plugin_category"=>"Monitoring",
        "last_scan_end"=>"2021-12-01 10:44:32",
        "scan_status"=>"Success",
        "plugin_status"=>"Active",
        "active"=>true
      }
    end

    before do
      stub_insights_request(:post, '/user_plugins', auth_key: insights_auth_key, user_id: user.id)
        .with(body: JSON.dump(user_plugin: plugin_data))
        .to_return(status: 201, body: JSON.dump(insights_create_plugin_response('name' => name)))
    end

    it 'responds with list of subscriptions' do
      post('/v3/insights_plugins', plugin_data, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
