require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user) }
  let!(:email) { create(:email) }
  let!(:organization) { create(:organization) }
  let!(:membership) { create(:membership) }

  describe '.find' do
    it 'finds user by ID' do
      expect(User.find(125283)).to_not be_nil
    end

    it 'retrieves login name' do
      expect(User.find(125283).login).to eql 'sinthetix'
    end

    it 'retrieves primary email address' do
      expect(User.find(125283).email).to eql 'aly@example.com'
    end
  end

  describe '.emails' do
    it 'finds additional email asscociated with a user' do
      expect(user.emails.first.email).to eql 'sinthetix@example.com'
    end
  end

  describe '.organizations' do
    it 'finds organization asscociated with the user' do
      expect(user.organizations.first.name).to eql 'Travis'
    end
  end
end
