describe Travis::API::V3::Services::InsightsSpotlightSummary::All, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }
  let(:time_start) { '2022-02-01' }
  let(:time_end) { '2022-02-27' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get("/v3/insights_spotlight_summary?time_start=#{time_start}&time_end=#{time_end}")

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:expected_json) do
      {
        "@type": "insights_spotlight_summary",
        "data": [
            {
                "id": 1,
                "user_id": 123,
                "repo_id": "1223",
                "build_status": "complete",
                "repo_name": "myrepo",
                "builds": 4,
                "duration": 47,
                "credits": 23,
                "user_license_credits_consumed": 20,
                "time": "2021-11-08T12:13:14.000Z"
            }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/insights_spotlight_summary', query:"time_start=#{time_start}&time_end=#{time_end}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(body: JSON.dump(insights_spotlight_summaries_response))
    end

    it 'responds with spotlight summary' do
      get("/v3/insights_spotlight_summary?time_start=#{time_start}&time_end=#{time_end}", {}, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
