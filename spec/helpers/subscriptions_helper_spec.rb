require 'rails_helper'

RSpec.describe SubscriptionsHelper, type: :helper do
  describe 'format_price' do
    it 'formats prices' do
      expect(helper.format_price(24900)).to eq('$249.00')
    end
  end

  describe 'format_plan' do
    it 'formats plans' do
      expect(helper.format_plan('travis-ci-twenty-builds-annual')).to eq('twenty builds annual')
    end
  end

  describe 'format_subscription' do
    let(:inactive_subscription) { create(:subscription) }
    let(:active_subscription) { create(:active_subscription) }
    let(:expired_subscription) { create(:expired_subscription) }

    it 'formats subscriptions' do
      expect(helper.format_subscription(inactive_subscription)).to eq('not active')
      expect(helper.format_subscription(active_subscription)).to include('active, twenty builds annual, expires')
      expect(helper.format_subscription(expired_subscription)).to include('inactive, twenty builds annual, expired')
    end
  end
end
