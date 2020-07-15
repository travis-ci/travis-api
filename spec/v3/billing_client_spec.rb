describe Travis::API::V3::BillingClient, billing_spec_helper: true do
  let(:billing) { described_class.new(user_id) }
  let(:user_id) { rand(999) }
  let(:billing_url) { 'https://billing.travis-ci.com/' }
  let(:auth_key) { 'supersecret' }
  let(:organization) { FactoryBot.create(:org, login: 'travis') }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = auth_key
  end

  let(:subscription_id) { rand(999) }
  let(:invoice_id) { "TP#{rand(999)}" }

  describe '#get_subscription' do
    subject { billing.get_subscription(subscription_id) }

    it 'returns the subscription' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(billing_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id } )))
      expect(subject).to be_a(Travis::API::V3::Models::Subscription)
      expect(subject.id).to eq(subscription_id)
      expect(subject.plan).to be_a(Travis::API::V3::Models::Plan)
    end

    it 'returns the subscription with discount' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(billing_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id } )))
      expect(subject).to be_a(Travis::API::V3::Models::Subscription)
      expect(subject.id).to eq(subscription_id)
      expect(subject.plan).to be_a(Travis::API::V3::Models::Plan)
      expect(subject.discount).to be_a(Travis::API::V3::Models::Discount)
    end

    it 'raises error if subscription is not found' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}", auth_key: auth_key, user_id: user_id)
        .to_return(status: 404, body: JSON.dump(error: 'Not Found'))

      expect { subject }.to raise_error(Travis::API::V3::NotFound)
    end
  end

  describe '#get_invoices_for_subscription' do
    subject { billing.get_invoices_for_subscription(subscription_id) }

    it 'returns a list of invoices' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}/invoices", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([{'id' => invoice_id, 'created_at' => Time.now, 'url' => 'https://billing-test.travis-ci.com/invoices/111.pdf', amount_due: 999 }]))
      expect(subject.first).to be_a(Travis::API::V3::Models::Invoice)
      expect(subject.first.id).to eq(invoice_id)
      expect(subject.first.amount_due).to eq(999)
    end

    it 'returns an empty list if there are no invoices' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}/invoices", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([]))

        expect(subject.size).to eq 0
    end
  end

  describe '#get_invoices_for_v2_subscription' do
    subject { billing.get_invoices_for_v2_subscription(subscription_id) }

    it 'returns a list of invoices' do
      stub_billing_request(:get, "/v2/subscriptions/#{subscription_id}/invoices", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([{'id' => invoice_id, 'created_at' => Time.now, 'url' => 'https://billing-test.travis-ci.com/invoices/111.pdf', amount_due: 999 }]))
      expect(subject.first).to be_a(Travis::API::V3::Models::Invoice)
      expect(subject.first.id).to eq(invoice_id)
      expect(subject.first.amount_due).to eq(999)
    end

    it 'returns an empty list if there are no invoices' do
      stub_billing_request(:get, "/v2/subscriptions/#{subscription_id}/invoices", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([]))

        expect(subject.size).to eq 0
    end
  end

  describe '#all' do
    subject { billing.all }

    let(:permissions) { [{'owner' => {'type' => 'Organization', 'id' => 1}, 'create' => true}] }

    it 'returns the list of subscriptions' do
      stub_billing_request(:get, '/subscriptions', auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(subscriptions: [billing_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id })], permissions: permissions))

      expect(subject.subscriptions.size).to eq 1
      expect(subject.subscriptions.first.id).to eq(subscription_id)
      expect(subject.permissions).to eq(permissions)
    end
  end

  describe '#all_v2' do
    subject { billing.all_v2 }

    let(:permissions) { [{'owner' => {'type' => 'Organization', 'id' => 1}, 'create' => true}] }

    it 'returns the list of subscriptions' do
      stub_billing_request(:get, '/v2/subscriptions', auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(subscriptions: [billing_v2_subscription_response_body('id' => subscription_id, 'owner' => { 'type' => 'Organization', 'id' => organization.id })], permissions: permissions))

      expect(subject.subscriptions.size).to eq 1
      expect(subject.subscriptions.first.id).to eq(subscription_id)
      expect(subject.permissions).to eq(permissions)
    end
  end

  describe '#update_address' do
    let(:address_data) { { 'address' => 'Rigaer Strasse' } }
    subject { billing.update_address(subscription_id, address_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/address", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(address_data))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_v2_address' do
    let(:address_data) { { 'address' => 'Rigaer Strasse' } }
    subject { billing.update_v2_address(subscription_id, address_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/v2/subscriptions/#{subscription_id}/address", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(address_data))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_plan' do
    let(:plan_data) { { 'plan' => 'travis-ci-ten-builds' } }
    subject { billing.update_plan(subscription_id, plan_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/plan", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(plan_data))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_creditcard' do
    let(:creditcard_token) { 'token' }
    subject { billing.update_creditcard(subscription_id, creditcard_token) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/creditcard", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(token: creditcard_token))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_v2_creditcard' do
    let(:creditcard_token) { 'token' }
    subject { billing.update_v2_creditcard(subscription_id, creditcard_token) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/v2/subscriptions/#{subscription_id}/creditcard", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(token: creditcard_token))
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#resubscribe' do
    subject { billing.resubscribe(subscription_id) }

    it 'requests the resubscription' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/resubscribe", auth_key: auth_key, user_id: user_id)
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#cancel_subscription' do
    let(:reason_data) { { 'reason' => 'Other', 'reason_details' => 'Cancellation details go here' } }
    subject { billing.cancel_subscription(subscription_id, reason_data) }

    it 'requests the cancelation of a subscription' do
      stubbed_request = stub_billing_request(:post, "/subscriptions/#{subscription_id}/cancel", auth_key: auth_key, user_id: user_id)
        .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#create_subscription' do
    let(:subscription_data) {{ 'address' => 'Rigaer' }}
    subject { billing.create_subscription(subscription_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_billing_request(:post, "/subscriptions", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(subscription_data))
        .to_return(status: 201, body: JSON.dump(billing_subscription_response_body('id' => 456, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id })))

      expect(subject.id).to eq(456)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#create_v2_subscription' do
    let(:subscription_data) {{ 'address' => 'Rigaer' }}
    subject { billing.create_v2_subscription(subscription_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_billing_request(:post, "/v2/subscriptions", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(subscription_data))
        .to_return(status: 201, body: JSON.dump(billing_v2_subscription_response_body('id' => 456, 'owner' => { 'type' => 'Organization', 'id' => organization.id })))

      expect(subject.id).to eq(456)
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#pay' do
    subject { billing.pay(subscription_id) }

    it 'requests to retry payment' do
      stubbed_request = stub_billing_request(:post, "/subscriptions/#{subscription_id}/pay", auth_key: auth_key, user_id: user_id)
        .to_return(status: 200, body: JSON.dump(billing_subscription_response_body('id' => subscription_id, 'client_secret' => 'client_secret', 'owner' => { 'type' => 'Organization', 'id' => organization.id })))

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#pay_v2' do
    subject { billing.pay_v2(subscription_id) }

    it 'requests to retry payment' do
      stubbed_request = stub_billing_request(:post, "/v2/subscriptions/#{subscription_id}/pay", auth_key: auth_key, user_id: user_id)
        .to_return(status: 200, body: JSON.dump(billing_v2_subscription_response_body('id' => subscription_id, 'owner' => { 'type' => 'Organization', 'id' => organization.id })))

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#trials' do
    subject { billing.trials }
    let(:trial_id) { rand(999) }

    it 'returns the trials' do
      stub_billing_request(:get, '/trials', auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([billing_trial_response_body('id' => trial_id, 'owner' => { 'type' => 'Organization', 'id' => organization.id })]))
      expect(subject.size).to eq 1
      expect(subject.first.id).to eq(trial_id)
    end
  end

  describe '#get_coupon' do
    subject { billing.get_coupon(coupon_code) }
    let(:coupon_code) { '10_BUCKS_OFF' }
    let(:billing_response) { { body: JSON.dump(billing_coupon_response_body) } }

    before do
      stub_billing_request(:get, "/coupons/#{coupon_code}", auth_key: auth_key, user_id: user_id)
        .to_return(billing_response)
    end

    it 'returns the coupon model' do
      expect(subject.name).to eq '10 bucks off!'
    end

    context 'when coupon not found' do
      let(:billing_response) { { status: 404, body: JSON.dump({'error' => "No such coupon: #{coupon_code}"}) } }
      let(:coupon_code) { 'InVaLiDcOuPoN' }

      it 'returns error' do
        expect { subject }.to raise_error(Travis::API::V3::NotFound)
      end
    end
  end


  describe '#plans_for' do
    describe '#organization' do
      subject { billing.plans_for_organization(organization.id) }

      it 'returns the list of plans for an organization' do
        stub_request(:get, "#{billing_url}plans_for/organization/#{organization.id}").with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
          .to_return(body: JSON.dump([billing_plan_response_body('id' => 'plan-id')]))

        expect(subject.size).to eq 1
        expect(subject.first.id).to eq('plan-id')
      end
    end

    describe '#user' do
      subject { billing.plans_for_user }

      it 'returns the list of plans for an user' do
        stub_request(:get, "#{billing_url}plans_for/user").with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
          .to_return(body: JSON.dump([billing_plan_response_body('id' => 'plan-id')]))

        expect(subject.size).to eq 1
        expect(subject.first.id).to eq('plan-id')
      end
    end
  end

  describe '#update_organization_billing_permission' do
    let(:billing_admin_only) { { billing_admin_only: true } }
    subject { billing.update_organization_billing_permission(organization.id, billing_admin_only) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/organization/permission_update/#{organization.id}", auth_key: auth_key, user_id: user_id)
                            .with(body: JSON.dump(billing_admin_only))
                            .to_return(status: 204)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end
end
