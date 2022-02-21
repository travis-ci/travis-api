describe Travis::API::V3::Services::InsightsPlugin::GetScanLogs, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }
  let(:plugin_id) { 1 }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get("/v3/insights_plugin/#{plugin_id}/get_scan_logs")

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:expected_json) do
      {
        "@type"=>"insights_plugin_scan_logs",
        "meta"=>{
          "scan_status_in_progress"=>true
        },
        "scan_logs"=>[
          {
            "id"=>97396,
            "user_plugin_id"=>255,
            "test_template_id"=>nil,
            "log_type"=>"notifications",
            "text"=>"Scheduling scan", 
            "additional_text_type"=>nil,
            "additional_text"=>nil,
            "created_at"=>"2021-11-18 04:00:05"
          },
          {
            "id"=>97432,
            "user_plugin_id"=>255,
            "test_template_id"=>nil,
            "log_type"=>"plugin",
            "text"=>"Scan started at",
            "additional_text_type"=>nil,
            "additional_text"=>nil,
            "created_at"=>"2021-11-18 04:00:07"
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, "/user_plugins/#{plugin_id}/get_scan_logs", auth_key: insights_auth_key, user_id: user.id)
          .to_return(body: JSON.dump(insights_scan_log_response))
    end

    it 'responds with authenticate result' do
      get("/v3/insights_plugin/#{plugin_id}/get_scan_logs", {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
