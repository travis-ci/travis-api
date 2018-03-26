describe Travis::API::V3::BillingClient, billing_spec_helper: true do
  let(:billing) { described_class.new(user_id) }
  let(:user_id) { rand(999) }
  let(:billing_url) { 'https://billing.travis-ci.com/' }
  let(:auth_key) { 'supersecret' }
  let(:organization) { Factory(:org, login: 'travis') }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = auth_key
  end

  let(:subscription_id) { rand(999) }

  describe '#get_subscription' do
    subject { billing.get_subscription(subscription_id) }

    it 'returns the subscription' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}", auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump(billing_response_body('id' => subscription_id, 'plan' => 'travis-ci-two-builds', 'owner' => { 'type' => 'Organization', 'id' => organization.id } )))
      expect(subject).to be_a(Travis::API::V3::Models::Subscription)
      expect(subject.id).to eq(subscription_id)
      expect(subject.plan).to eq('travis-ci-two-builds')
    end

    it 'raises error if subscription is not found' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}", auth_key: auth_key, user_id: user_id)
        .to_return(status: 404)

      expect { subject }.to raise_error(described_class::NotFoundError)
    end
  end

  describe '#all' do
    subject { billing.all }

    it 'returns the list of subscriptions' do
      stub_billing_request(:get, '/subscriptions', auth_key: auth_key, user_id: user_id)
        .to_return(body: JSON.dump([billing_response_body('id' => subscription_id, 'owner' => { 'type' => 'Organization', 'id' => organization.id })]))

      expect(subject.size).to eq 1
      expect(subject.first.id).to eq(subscription_id)
    end
  end

  describe '#update_address' do
    let(:address_data) { { 'address' => 'Rigaer Strasse' } }
    subject { billing.update_address(subscription_id, address_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/address", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(subscription: address_data))
        .to_return(status: 202)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#update_creditcard' do
    let(:creditcard_data) { { 'cc_owner' => 'Hans' } }
    subject { billing.update_creditcard(subscription_id, creditcard_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/creditcard", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(subscription: creditcard_data))
        .to_return(status: 203)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  describe '#create_subscription' do
    let(:subscription_data) {{ 'address' => 'Rigaer' }}
    subject { billing.create_subscription(subscription_data) }

    it 'requests the creation and returns the representation' do
      stubbed_request = stub_billing_request(:post, "/subscriptions", auth_key: auth_key, user_id: user_id)
        .with(body: JSON.dump(subscription: subscription_data))
        .to_return(status: 202, body: JSON.dump(billing_response_body('id' => 456, 'owner' => { 'type' => 'Organization', 'id' => organization.id })))

      expect(subject.id).to eq(456)
      expect(stubbed_request).to have_been_made
    end
  end
end
