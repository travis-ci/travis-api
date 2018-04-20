describe Travis::API::V3::Services::Plans::All, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/plans')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { Factory(:user) }
    let(:organization) { Factory(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}

    before do
      stub_billing_request(:get, '/plans', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: JSON.dump([
          billing_plan_response_body(
            'id' => 'travis-ci-one-build',
            'name' => 'Bootstrap',
            'builds' => 1,
            'annual' => false,
            'price' => 2500,
            'currency' => 'USD'
          ),
          billing_plan_response_body(
            'id' => 'travis-ci-ten-builds',
            'name' => 'Startup',
            'builds' => 10,
            'annual' => false,
            'price' => 12500,
            'currency' => 'USD'
          ),
      ]))
    end

    it 'responds with list of plans' do
      get('/v3/plans', {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'plans',
        '@representation' => 'standard',
        '@href' => '/v3/plans',
        'plans' => [
          {
            '@type' => 'plan',
            '@representation' => 'standard',
            'id' => 'travis-ci-one-build',
            'name' => 'Bootstrap',
            'builds' => 1,
            'annual' => false,
            'price' => 2500,
            'currency' => 'USD'
          },
          {
            '@type' => 'plan',
            '@representation' => 'standard',
            'id' => 'travis-ci-ten-builds',
            'name' => 'Startup',
            'builds' => 10,
            'annual' => false,
            'price' => 12500,
            'currency' => 'USD'
          }
        ]
      })
    end
  end
end
