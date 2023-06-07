describe Travis::API::V3::Services::V2Subscription::UpdatePaymentDetails, set_app: true, billing_spec_helper: true do
  let(:billing_url) { 'http://billingfake.travis-ci.com' }
  let(:billing_auth_key) { 'secret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = billing_auth_key
    Travis.config.antifraud.captcha_block_duration = 24
  end

  context 'unauthenticated' do
    it 'responds 403' do
      patch('/v3/v2_subscription/123/payment_details', { })

      expect(last_response.status).to eq(403)
    end
  end

  context 'authenticated' do
    let(:user) { FactoryBot.create(:user) }
    let(:token) { Travis::Api::App::AccessToken.create(user: user, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}",
                     'CONTENT_TYPE' => 'application/json' }}
    let(:address_data) { {
      'address' => 'Rigaer Strasse',
      'first_name' => 'Travis',
      'last_name' => 'Schmidt',
      'company' => 'Travis',
      'city' => 'Berlin',
      'country' => 'Germany',
      'zip_code' => '10001',
      'billing_email' => 'travis@example.org',
      'token' => 'token_from_stripe'
      } }
    let(:subscription_id) { rand(999) }

    let!(:stubbed_request_address) do
      stub_billing_request(:patch, "/v2/subscriptions/#{subscription_id}/address", auth_key: billing_auth_key, user_id: user.id)
        .with(body: {
            'first_name' => 'Travis',
            'last_name' => 'Schmidt',
            'company' => 'Travis',
            'address' => 'Rigaer Strasse',
            'city' => 'Berlin',
            'country' => 'Germany',
            'zip_code' => '10001',
            'billing_email' => 'travis@example.org'
          })
        .to_return(status: 204)
    end

    let!(:stubbed_request_creditcard) do
      stub_billing_request(:patch, "/v2/subscriptions/#{subscription_id}/creditcard", auth_key: billing_auth_key, user_id: user.id)
      .with(body: { 'token' => 'token_from_stripe', 'fingerprint' => nil })
      .to_return(status: 204)
    end

    context 'user is clean' do
      before do
        Travis.redis.del("recaptcha_attempts_v2_#{subscription_id}")
      end

      it 'updates the address and credit card' do
        allow_any_instance_of(Travis::API::V3::RecaptchaClient).to receive(:verify).and_return(true)

        patch("/v3/v2_subscription/#{subscription_id}/payment_details", JSON.generate(address_data), headers)

        expect(last_response.status).to eq(204)
        expect(stubbed_request_address).to have_been_made.once
        expect(stubbed_request_creditcard).to have_been_made.once
      end
    end

    context 'user failed captcha check' do
      before do
        Travis.redis.setex("recaptcha_attempts_v2_#{subscription_id}", Travis.config.antifraud.captcha_block_duration, 1)
      end

      it 'updates the address and credit card' do
        allow_any_instance_of(Travis::API::V3::RecaptchaClient).to receive(:verify).and_return(false)

        patch("/v3/v2_subscription/#{subscription_id}/payment_details", JSON.generate(address_data), headers)

        expect(last_response.status).to eq(400)
        expect(stubbed_request_address).to_not have_been_made
        expect(stubbed_request_creditcard).to_not have_been_made
      end
    end
  end
end
