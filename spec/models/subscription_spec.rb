require 'rails_helper'

RSpec.describe Subscription, type: :model do
  let!(:valid_subscription) { create :active_subscription }

  describe '.active?' do
    let!(:invalid_subscription) { create :expired_subscription }
    let!(:missing_token_subscription) { create :subscription_missing_token, valid_to: 1.week.from_now }
    let!(:missing_token_invalid_subscription) { create :subscription }

    it 'returns true for valid subscription with cc_token' do
      expect(valid_subscription.active?).to be true
    end

    it 'returns false for invalid subscriptions' do
      expect(invalid_subscription.active?).to be false
      expect(missing_token_subscription.active?).to be false
      expect(missing_token_invalid_subscription.active?).to be false
    end
  end

  describe 'valid_to' do
    it 'gives a date wihout a time' do
      expect(valid_subscription.valid_to).to eq(1.week.from_now.to_date)
    end
  end

  describe 'postal_address' do
    it 'returns the full address' do
      expect(valid_subscription.postal_address).to eq("Katrin Mustermann, Travis CI\nNice Street 12\n12344 Berlin\nGermany")
    end
  end
end
