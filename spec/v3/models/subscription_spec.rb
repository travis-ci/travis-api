describe Travis::API::V3::Models::Subscription do
  let!(:subscription) { Travis::API::V3::Models::Subscription.create}
  # Factory.create(:request, event_type: event_type) }

  describe "Subscription inactive" do
    before { subscription.update_attributes(cc_token: nil, valid_to: Time.now - 100)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be false }
  end

  describe "Subscription active" do
    before { subscription.update_attributes(cc_token: 'tok_0rlTxxxxxxx', valid_to: Time.now + 100)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be true }
  end
end
