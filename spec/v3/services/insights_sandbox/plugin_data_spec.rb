describe Travis::API::V3::Services::InsightsSandbox::PluginData, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/insights_sandbox/plugin_data')

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
        "@type"=>"insights_sandbox_plugin_data",
        "data"=>{
          "Plugins"=>[
            {
              "id"=>255,
              "plugin_category"=>"monitoring",
              "plugin_type"=>"sre",
              "scan_logs"=>[
                {
                  "additional_text"=>nil,
                  "additional_text_type"=>nil,
                  "created_at"=>"2021-11-18T04:00:05.072Z",
                  "id"=>97396,
                  "log_type"=>"notifications",
                  "tenant_id"=>39,
                  "test_template_id"=>nil,
                  "text"=>"Scheduling scan",
                  "updated_at"=>"2021-11-18T04:00:05.072Z",
                  "user_plugin_id"=>255
                },
                {
                  "additional_text"=>nil,
                  "additional_text_type"=>nil,
                  "created_at"=>"2021-11-18T04:00:07.010Z",
                  "id"=>97432,
                  "log_type"=>"plugin",
                  "tenant_id"=>39,
                  "test_template_id"=>nil,
                  "text"=>"Scan started at",
                  "updated_at"=>"2021-11-18T04:00:07.010Z",
                  "user_plugin_id"=>255
                },
                {
                  "additional_text"=>"",
                  "additional_text_type"=>"",
                  "created_at"=>"2021-11-18T04:00:07.068Z",
                  "id"=>97435,
                  "log_type"=>"plugin",
                  "tenant_id"=>39,
                  "test_template_id"=>nil,
                  "text"=>"Accessing APIs:",
                  "updated_at"=>"2021-11-18T04:00:07.068Z",
                  "user_plugin_id"=>255
                },
                {
                  "additional_text"=>"- User Plugins",
                  "additional_text_type"=>"info",
                  "created_at"=>"2021-11-18T04:00:07.148Z",
                  "id"=>97438,
                  "log_type"=>"plugin",
                  "tenant_id"=>39,
                  "test_template_id"=>nil,
                  "text"=>"",
                  "updated_at"=>"2021-11-18T04:00:07.148Z",
                  "user_plugin_id"=>255
                }
              ],
              "user_id"=>28
            }
          ]
        }
      }
    end

    before do
      stub_insights_request(:post, '/sandbox/plugin_data', auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: insights_sandbox_plugin_data_response)
    end

    it 'responds with list of subscriptions' do
      post('/v3/insights_sandbox/plugin_data', { plugin_type: plugin_type }, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
