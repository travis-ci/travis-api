describe Travis::API::V3::Services::CreditsCalculator::Calculator, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      post('/v3/credits_calculator', { users: 6, executions: [] }, {})

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    let(:v2_response_body) { JSON.generate(billing_v2_credits_calculator_body) }

    let(:expected_json) do
      {
        '@type' => 'credits_results',
        '@representation' => 'standard',
        'credits_results' => [
          {
            '@type' => 'credits_result',
            '@representation' => 'standard',
            'users' => 3,
            'minutes' => nil,
            'os' => nil,
            'instance_size' => nil,
            'credits' => 25_000,
            'price' => 1_500
          },
          {
            '@type' => 'credits_result',
            '@representation' => 'standard',
            'users' => nil,
            'minutes' => 1000,
            'os' => 'linux',
            'instance_size' => '2x-large',
            'credits' => 250_000,
            'price' => 15_000
          }
        ]
      }
    end

    before do
      stub_billing_request(:post, '/usage/credits_calculator', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: v2_response_body)
    end

    it 'responds with list of credits results' do
      post('/v3/credits_calculator', { users: 6, executions: [] }, headers)
      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json(expected_json)
    end
  end
end
