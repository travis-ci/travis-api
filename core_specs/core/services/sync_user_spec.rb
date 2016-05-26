require 'spec_helper'

describe Travis::Services::SyncUser do
  include Travis::Testing::Stubs

  let(:publisher) { stub('publisher', :publish => true) }
  let(:service)   { described_class.new(user, {}) }

  describe 'given the user is not currently syncing' do
    before :each do
      user.stubs(:update_column)
      user.stubs(:syncing?).returns(false)
    end

    it 'enqueues a sync job' do
      Travis::Sidekiq::SynchronizeUser.expects(:perform_async).with(user.id)
      service.run
    end

    it 'sets the user to syncing' do
      user.expects(:update_column).with(:is_syncing, true)
      service.run
    end
  end

  describe 'given the user is currently syncing' do
    before :each do
      user.stubs(:syncing?).returns(true)
    end

    it 'does not set the user to syncing' do
      user.expects(:update_column).never
      service.run
    end
  end
end
