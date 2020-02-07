describe Travis::API::V3::Services::Coupons::Find, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/coupons/50_OFF')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:organization) { FactoryBot.create(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before do
      stub_billing_request(:get, '/coupons/50_OFF', auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: JSON.dump('id' => '50_OFF', 'name' => '50 OFF!', 'percent_off' => 50.0, 'value_off' => nil, valid: true))
    end

    it 'responds with a coupon' do
      get('/v3/coupons/50_OFF', {}, headers)

      expect(last_response.status).to eq(200)

      expect(parsed_body).to eql_json({
        '@type' => 'coupon',
        '@representation' => 'standard',
        'id' => '50_OFF',
        'name' => '50 OFF!',
        'percent_off' => 50.0,
        'amount_off' => nil,
        'valid' => true
      })
    end
  end
end
