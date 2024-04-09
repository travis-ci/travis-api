describe Travis::API::V3::Models::Subscription do
  let(:user) { FactoryBot.create(:user) }
  let(:attributes) do
    {
      'id' => 1,
      'permissions' => { 'read' => true, 'write' => true },
      'valid_to' => Date.today.to_s,
      'created_at' => Date.today.to_s,
      'cancellation_requested' => false,
      'plan' => {
        'id' => 123,
        'name' => 'some_name',
        'builds' => 1,
        'price' => 100500,
        'currency' => 'EUR',
        'annual' => true
      },
      'status' => 'incomplete',
      'source' => 'stripe',
      'owner' => { 'id' => user.id, 'type' => 'User'},
      'client_secret' => 'secret',
      'payment_intent' => { 'status' => 'requires_action', 'client_secret' => 'abc', 'last_payment_error' => {} }
    }
  end

  subject { Travis::API::V3::Models::Subscription.new(attributes) }

  context 'basic fields' do
    it 'returns basic fields' do
      expect(subject.id).to eq(attributes['id'])
      expect(subject.permissions).to be_a(Travis::API::V3::Models::BillingPermissions)
      expect(subject.owner).to be_a(Travis::API::V3::Models::User)
      expect(subject.payment_intent).to be_a(Travis::API::V3::Models::PaymentIntent)
    end
  end
end
