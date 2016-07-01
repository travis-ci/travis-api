require 'rails_helper'

RSpec.describe Subscription, type: :model do
  describe '.active?' do
    let!(:valid_subscription) { create :subscription, cc_token: 'tok_1076247Biz', valid_to: 1.week.from_now }
    let!(:invalid_subscription) { create :subscription, cc_token: 'tok_1076247Biz', valid_to: '2015-07-12 09:16:24' }
    let!(:missing_token_subscription) { create :subscription, valid_to: 1.week.from_now }
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
end
