describe Travis::API::V3::Services::V2Subscription::Invoices, set_app: true, billing_spec_helper: true do
  let(:parsed_body) { JSON.load(last_response.body) }
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
  end

  context 'unauthenticated' do
    it 'responds 403' do
      get('/v3/v2_subscriptions')

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:organization) { FactoryBot.create(:org, login: 'travis') }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    let(:invoice_id) { "TP#{rand(999)}" }
    let(:created_at) { '2018-04-17T18:30:32Z' }
    let(:url) { 'https://billing-test.travis-ci.com/invoices/111.pdf' }
    let(:amount_due) { 100 }
    let(:status) { 'paid' }
    let(:subscription_id) { rand(999) }
    let(:cc_last_digits) { '4242' }

    before do
      stub_billing_request(:get, "/v2/subscriptions/#{subscription_id}/invoices", auth_key: billing_auth_key, user_id: user.id)
        .to_return(status: 200, body: [{'id' => invoice_id, 'created_at' => created_at, 'url' => url, 'amount_due' => amount_due, 'status' => status, 'cc_last_digits' => cc_last_digits }])
    end

    it 'responds with list of subscriptions' do
      get("/v3/v2_subscription/#{subscription_id}/invoices", {}, headers)

      expect(last_response.status).to eq(200)
      expect(parsed_body).to eql_json({
        '@type' => 'invoices',
        '@representation' => 'standard',
        '@href' => "/v3/v2_subscription/#{subscription_id}/invoices",
        'invoices' => [{
          '@type' => 'invoice',
          '@representation' => 'standard',
          'id' => invoice_id,
          'created_at' => created_at,
          'url' => url,
          'amount_due' => amount_due,
          'status' => status,
          'cc_last_digits' => cc_last_digits
        }]
      })
    end
  end
end
