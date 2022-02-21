describe Travis::API::V3::Services::InsightsSandbox::RunQuery, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/insights_sandbox/run_query')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:plugin_id) { '333' }
    let(:query) { 'test' }
    let(:expected_json) do
      {
        "@type"=>"insights_sandbox_query_result",
        "negative_results"=>[false],
        "positive_results"=>nil,
        "success"=>true
      }
    end

    before do
      stub_insights_request(:post, '/sandbox/run_query', auth_key: insights_auth_key, user_id: user.id)
        .to_return(status: 201, body: JSON.dump(insights_sandbox_query_response))
    end

    it 'responds with list of subscriptions' do
      post('/v3/insights_sandbox/run_query', { plugin_id: plugin_id, query: query }, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
