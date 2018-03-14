describe Travis::API::V3::Billing do
  let(:billing) { described_class.new(user_id) }
  let(:user_id) { rand(999) }
  let(:billing_url) { 'https://billing.travis-ci.com/' }
  let(:auth_key) { 'supersecret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = auth_key
  end

  let(:subscription_id) { rand(999) }

  describe '#get_subscription' do
    subject { billing.get_subscription(subscription_id) }

    it 'returns the subscription' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}").to_return(body: JSON.dump(id: subscription_id))
      expect(subject).to be_a(described_class::Subscription)
      expect(subject.id).to eq(subscription_id)
      # TODO: More attributes
    end

    it 'raises error if subscription is not found' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}").to_return(status: 404)

      expect { subject }.to raise_error(described_class::NotFoundError)
    end
  end

  describe '#all' do
    subject { billing.all }

    it 'returns the list of subscriptions' do
      stub_billing_request(:get, '/subscriptions').to_return(body: JSON.dump([{id: subscription_id}]))

      expect(subject).to eq([described_class::Subscription.new('id' => subscription_id)])
    end
  end

  describe '#update_address' do
    let(:address_data) { { 'street' => 'Rigaer Strasse' } }
    subject { billing.update_address(subscription_id, address_data) }

    it 'requests the update' do
      stubbed_request = stub_billing_request(:patch, "/subscriptions/#{subscription_id}/address").with(body: JSON.dump(address_data)).to_return(status: 202)

      expect { subject }.to_not raise_error
      expect(stubbed_request).to have_been_made
    end
  end

  def stub_billing_request(method, path)
    url = URI(billing_url).tap do |url|
      url.path = path
    end.to_s
    stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
  end
end
