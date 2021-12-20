describe Travis::API::V3::Services::InsightsPlugins::TemplatePluginTests, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/insights_plugins/template_plugin_tests')

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
        "@type"=>"insights_plugin_tests",
        "template_tests"=>[
          {
            "id"=>3232,
            "name"=>"This is a test probe"
          },
          {
            "id"=>3234,
            "name"=>"This is a test probe 2"
          }
        ],
        "plugin_category"=>"Monitoring"
      }
    end

    before do
      stub_insights_request(:get, "/user_plugins/#{plugin_type}/template_plugin_tests", auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_template_plugin_tests_response))
    end

    it 'responds with list of subscriptions' do
      get("/v3/insights_plugins/template_plugin_tests?plugin_type=#{plugin_type}", {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
