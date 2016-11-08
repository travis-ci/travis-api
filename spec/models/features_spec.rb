require 'rails_helper'

RSpec.describe Features, type: :model do
  let!(:user) { create(:user) }
  let(:redis) { Travis::DataStores.redis }

  before { redis.sadd('feature:cron:users', "#{user.id}")
           redis.sadd('feature:coffee:users', "#{user.id + 1}")
           redis.set('feature:resubscribe:disabled', 1) }

  before(:each) { ::Features.reload }

  # count, for, for_kind and members can also be used with 'repositories' and 'organizations' instead of 'users'

  describe 'count' do
    it 'gives the number of users for a feature' do
      expect(Features.count('users', 'cron')).to eq(1)
    end
  end

  describe 'for' do
    it 'gives all features for a user (enabled and disabled)' do
      expect(Features.for(user)).to eq({'coffee'=>false, 'cron'=>true})
    end
  end

  describe 'for_kind' do
    it "gives all features for kind 'users'" do
      expect(Features.for_kind('users')).to eq(['coffee', 'cron'])
    end
  end

  describe 'global' do
    it 'gives array of global features (enabled and disabled)' do
      expect(Features.global).to eq({'education'=>false, 'multi_os'=>false, 'osx_alt_image'=>false, 'resubscribe'=>true})
    end
  end

  describe 'members' do
    it "gives database entries for kind 'users' with feature 'cron'" do
      expect(Features.members('users', 'cron')).to include(user)
    end
  end
end
