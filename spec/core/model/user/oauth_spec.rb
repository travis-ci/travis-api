require 'spec_helper'

describe User::Oauth do
  include Support::ActiveRecord

  let(:user)    { Factory(:user, :github_oauth_token => 'token') }
  let(:payload) { GITHUB_PAYLOADS[:oauth] }

  describe 'find_or_create_by' do
    def call(payload)
      User::Oauth.find_or_create_by(payload)
    end

    it 'marks users as recently_signed_up' do
      call(payload).should be_recently_signed_up
    end

    it 'does not mark existing users as recently_signed_up' do
      call(payload)
      call(payload).should_not be_recently_signed_up
    end

    it 'updates changed attributes' do
      call(payload).attributes.slice(*GITHUB_OAUTH_DATA.keys).should == GITHUB_OAUTH_DATA
    end
  end

  describe 'attributes_from' do
    it 'returns required data' do
      User::Oauth.attributes_from(payload).should == GITHUB_OAUTH_DATA
    end
  end
end
