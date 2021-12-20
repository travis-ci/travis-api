describe Travis::API::V3::Services::InsightsPlugins::RunScan, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      delete('/v3/insights_plugins/run_scan')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:expected_json) do
      {
        "@type"=>"plugins",
        "@representation"=>"standard",
        "@pagination"=>
        {
          "limit"=>25,
          "offset"=>0,
          "count"=>0
        },
        "plugins"=>[]
      }
    end

    before do
      stub_insights_request(:get, '/user_plugins/run_scan', auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 200, body: '')
    end

    it 'responds with list of subscriptions' do
      get('/v3/insights_plugins/run_scan', {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
