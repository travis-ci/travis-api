describe Travis::API::V3::Models::Subscription do
  let!(:subscription) { Travis::API::V3::Models::Subscription.create(source: 'stripe')}

  describe "Subscription inactive" do
    before { subscription.update_attributes(valid_to: Time.now - 1.day)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be false }
  end

  describe "Subscription active" do
    before { subscription.update_attributes(valid_to: Time.now + 1.day)}
    example { Travis::API::V3::Models::Subscription.find_by_id(subscription.id).active?.should be true }
  end
end
