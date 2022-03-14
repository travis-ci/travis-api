describe Travis::API::V3::Services::SpotlightSummary::All, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }
  let(:time_start) { '2022-02-01' }
  let(:time_end) { '2022-03-10' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get("/v3/spotlight_summary?time_start=#{time_start}&time_end=#{time_end}")

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before do
      stub_insights_request(:get, '/spotlight_summary', query: "time_start=#{time_start}&time_end=#{time_end}", auth_key: insights_auth_key, user_id: user.id)
        .to_return(body: JSON.dump(spotlight_summaries_response))
    end

    it 'responds with spotlight summary' do
      get("/v3/spotlight_summary?time_start=#{time_start}&time_end=#{time_end}", {}, headers)
      expect(last_response.status).to eq(200)
    end
  end
end
