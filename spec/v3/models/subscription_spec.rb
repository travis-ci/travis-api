describe Travis::API::V3::Models::Subscription do
  let!(:subscription) { Travis::API::V3::Models::Subscription.create}

  describe "Subscription inactive" do
    before { subscription.update_attributes(cc_token: nil, valid_to: Time.now - 100)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be false }
  end

  describe "Subscription active" do
    before { subscription.update_attributes(cc_token: 'tok_0rlTxxxxxxx', valid_to: Time.now + 100)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be true }
  end
end
