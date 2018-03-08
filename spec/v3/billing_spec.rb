describe Travis::API::V3::Billing do
  let(:billing) { described_class.new(user_id) }
  let(:user_id) { rand(999) }
  let(:billing_url) { 'https://billing.travis-ci.com/' }
  let(:auth_key) { 'supersecret' }

  before do
    Travis.config.billing.url = billing_url
    Travis.config.billing.auth_key = auth_key
  end

  describe '#get_subscription' do
    subject { billing.get_subscription(subscription_id) }

    let(:subscription_id) { rand(999) }

    it 'returns the subscription' do
      stub_billing_request(:get, "/subscriptions/#{subscription_id}").to_return(body: JSON.dump(id: subscription_id))
      subject.should be_a(described_class::Subscription)
      subject.id.should == subscription_id
      # TODO: More attributes
    end

    # TODO: What if not found
  end

  def stub_billing_request(method, path)
    url = URI(billing_url).tap do |url|
      url.path = path
    end.to_s
    stub_request(method, url).with(basic_auth: ['_', auth_key], headers: { 'X-Travis-User-Id' => user_id })
  end
end
