describe Travis::API::V3::Queries::Subscription do
  let(:user) {Factory(:user, login: 'svenfuchs')}
  let(:org) { Travis::API::V3::Models::Organization.new(login: 'example-org', github_id: 1234) }
  let!(:subscription) { Travis::API::V3::Models::Subscription.create(owner: org, valid_to: Time.now.utc, source: "stripe", status: "subscribed", selected_plan: "travis-ci-two-builds") }

  before do
    Travis.config.billing = {url:'https://billing-v2.travis-ci.com'}
    ENV['BILLING_AUTH_KEY'] = 'abc123'
  end

  it 'calls Billing to make a request to create a Subscription' do

    Travis::API::V3::Billing.any_instance.stubs(:create_subscription).returns({status: 200})
    subscription_query = described_class.new({}, Subscription)
    subscription_query.create(user.id, {}).should == {status: 200}
  end

  it 'calls Billing to make a request to cancel a Subscription' do
    Travis::API::V3::Billing.any_instance.stubs(:cancel_subscription).returns({status: 200})
    subscription_query = described_class.new({id: subscription.id}, Subscription)
    subscription_query.cancel(user.id).should == {status: 200}
  end

  it 'calls Billing to make a request to edit the address on a Subscription' do
    Travis::API::V3::Billing.any_instance.stubs(:edit_address).returns({status: 200})
    address_params = {zip_code: '10247', address: 'Rigaer Strasse 8', address2: nil, city: 'Berlin', state: nil, country: 'DE'}
    subscription_query = described_class.new({id: subscription.id}, Subscription)
    subscription_query.edit_address(user.id, address_params).should == {status: 200}
  end
end
