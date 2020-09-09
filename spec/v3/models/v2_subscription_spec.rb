describe Travis::API::V3::Models::V2Subscription do
  let(:user) { FactoryBot.create(:user) }
  let(:attributes) do
    {
      'id' => 'id',
      'permissions' => { 'read' => true, 'write' => true },
      'created_at' => Date.today.to_s,
      'plan_config' => {
        'id' => 'pro_tier_plan',
        'name' => 'Pro Tier Plan',
        'private_repos' => true,
        'starting_price' => 30000,
        'starting_users' => 10000,
        'private_credits' => 500000,
        'public_credits' => 40000,
      },
      'addons' => [{
        'id' => 7,
        'name' => 'OSS Build Credits',
        'plan_id' => 3,
        'addon_config_id' => 'oss_tier_credits',
        'type' => 'credit_public',
        'created_at' => Date.today.to_s,
        'updated_at' => Date.today.to_s,
        'current_usage_id' => 7,
        'current_usage' => {
          'id' => 7,
          'addon_id' => 7,
          'addon_quantity' => 40_000,
          'addon_usage' => 0,
          'remaining' => 40_000,
          'purchase_date' => Date.today.to_s,
          'valid_to' => Date.today.to_s,
          'status' => 'pending',
          'active' => false,
          'created_at' => Date.today.to_s,
          'updated_at' => Date.today.to_s
        }
      }],
      'source' => 'stripe',
      'owner' => { 'id' => user.id, 'type' => 'User'},
      'client_secret' => 'secret',
      'payment_intent' => { 'status' => 'requires_action', 'client_secret' => 'abc', 'last_payment_error' => {} }
    }
  end

  subject { Travis::API::V3::Models::V2Subscription.new(attributes) }

  context 'basic fields' do
    it 'returns basic fields' do
      expect(subject.id).to eq(attributes['id'])
      expect(subject.plan).to be_a(Travis::API::V3::Models::V2PlanConfig)
      expect(subject.permissions).to be_a(Travis::API::V3::Models::BillingPermissions)
      expect(subject.owner).to be_a(Travis::API::V3::Models::User)
      expect(subject.payment_intent).to be_a(Travis::API::V3::Models::PaymentIntent)
    end
  end
end
