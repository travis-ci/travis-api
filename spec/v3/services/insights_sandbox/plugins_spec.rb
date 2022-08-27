describe Travis::API::V3::Services::InsightsSandbox::Plugins, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/insights_sandbox/plugins')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:plugin_type) { 'sre' }
    let(:expected_json) do
      {
        "@type"=>"insights_sandbox_plugins",
        "plugins"=>[
          {
            "id"=>4,
            "name"=>"Travis Insights",
            "data"=>"{\n  \"Plugins\": [\n    {\n      \"id\": 255,\n      \"plugin_category\": \"monitoring\",\n      \"plugin_type\": \"sre\",\n      \"scan_logs\": [\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:05.072Z\",\n          \"id\": 97396,\n          \"log_type\": \"notifications\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scheduling scan\",\n          \"updated_at\": \"2021-11-18T04:00:05.072Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": null,\n          \"additional_text_type\": null,\n          \"created_at\": \"2021-11-18T04:00:07.010Z\",\n          \"id\": 97432,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Scan started at\",\n          \"updated_at\": \"2021-11-18T04:00:07.010Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"\",\n          \"additional_text_type\": \"\",\n          \"created_at\": \"2021-11-18T04:00:07.068Z\",\n          \"id\": 97435,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"Accessing APIs:\",\n          \"updated_at\": \"2021-11-18T04:00:07.068Z\",\n          \"user_plugin_id\": 255\n        },\n        {\n          \"additional_text\": \"- User Plugins\",\n          \"additional_text_type\": \"info\",\n          \"created_at\": \"2021-11-18T04:00:07.148Z\",\n          \"id\": 97438,\n          \"log_type\": \"plugin\",\n          \"tenant_id\": 39,\n          \"test_template_id\": null,\n          \"text\": \"\",\n          \"updated_at\": \"2021-11-18T04:00:07.148Z\",\n          \"user_plugin_id\": 255\n        }\n      ],\n      \"user_id\": 28\n    }\n  ]\n}",
            "ready"=>true
          }
        ],
        "in_progress"=>false,
        "no_plugins"=>false
      }
    end

    before do
      stub_insights_request(:post, '/sandbox/plugins', auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_sandbox_plugins_response))
    end

    it 'responds with list of subscriptions' do
      post('/v3/insights_sandbox/plugins', { plugin_type: plugin_type }, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
