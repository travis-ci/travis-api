require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user) }
  let!(:email) { create(:email) }
  let!(:organization) { create(:organization) }
  let!(:membership) { create(:membership) }

  describe '.login' do
    it 'retrieves login name' do
      expect(user.login).to eql 'sinthetix'
    end
  end

  describe '.login' do
    it 'retrieves primary email address' do
      expect(user.email).to eql 'aly@example.com'
    end
  end

  describe '.emails' do
    it 'finds additional email associated with a user' do
      expect(user.emails.first.email).to eql 'sinthetix@example.com'
    end
  end

  describe '.organizations' do
    it 'finds organization asscociated with the user' do
      expect(user.organizations.first.name).to eql 'Travis'
    end
  end
end
