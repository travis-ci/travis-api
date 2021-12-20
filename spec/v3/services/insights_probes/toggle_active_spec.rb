describe Travis::API::V3::Services::InsightsProbes::ToggleActive, set_app: true, insights_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:insights_url) { 'http://insightsfake.travis-ci.com' }
  let(:insights_auth_key) { 'secret' }

  before do
    Travis.config.new_insights.insights_url = insights_url
    Travis.config.new_insights.insights_auth_token = insights_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch('/v3/insights_probes/toggle_active')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:probe_ids) { ["123", "345"] }

    before do
      stub_insights_request(:put, '/probes/toggle_active', auth_key: insights_auth_key, user_id: user.id)
        .with(body: JSON.dump(toggle_ids: probe_ids))
        .to_return(status: 200, body: '')
    end

    it 'responds with list of subscriptions' do
      patch('/v3/insights_probes/toggle_active', { ids: probe_ids }, headers)
      expect(last_response.status).to eq(204)
    end
  end
end
