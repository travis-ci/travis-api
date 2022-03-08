describe Travis::API::V3::Services::SpotlightSummary::All, set_app: true, insights_spec_helper: true do
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
      get("/spotlight_summary?time_start=#{time_start}&time_end=#{time_end}")

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:expected_json) do
      {
        "@type": "spotlight_summary",
        "data": [
          {
            "id": 1,
            "user_id": 123,
            "repo_id": 1223,
            "build_status": 'complete',
            "repo_name": 'myrepo',
            "builds": 4,
            "duration": 47,
            "credits": 23,
            "license_credits": 20,
            "time": '2022-02-08'
          }
        ]
      }
    end

    before do
      stub_insights_request(:get, '/spotlight_summary', query:"time_start=#{time_start}&time_end=#{time_end}", auth_key: insights_auth_key, user_id: 123)
        .to_return(body: JSON.dump(spotlight_summaries_response))
    end

    it 'responds with spotlight summary' do
      stub_request(:get, "#{insights_url}/spotlight_summary?time_start=#{time_start}&time_end=#{time_end}").
        with( headers: { 'X-Travis-User-Id'=>'123' }).to_return(status: 200, body: '')
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
