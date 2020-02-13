describe Travis::API::V3::Services::Insights::ActiveRepos, set_app: true do
  let(:user) { FactoryBot.create(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
  let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
  let(:expected_data) { ['whatever'] }

  let!(:stubbed_request) do
    stub_request(:get, "#{Travis.config.insights.endpoint}/repos/active?owner_type=Organization&owner_id=1&rest-of-params=value").with(headers: { 'Authorization' => "Token token=\"#{Travis.config.insights.auth_token}\""}).to_return(status: 200, body: JSON.dump(expected_data), headers: { content_type: 'application/json' })
  end

  subject(:response) { get("/v3/insights/repos/active?owner_type=Organization&owner_id=1&rest-of-params=value", {}, headers) }

  it 'requests the metrics from the insights service' do
    expect(response.status).to eq(200)
    response_data = JSON.parse(response.body)
    expect(response_data['data']).to eq(expected_data)
    expect(response_data['@warnings']).to eq nil # no warnings about passing unexpected params
  end
end
