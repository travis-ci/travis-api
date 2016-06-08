require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user) }
  let!(:email) { create(:email) }

  describe '.find' do
    it 'finds user by ID' do
      expect(User.find(125283)).to_not be_nil
    end

    it 'retrieves login name' do
      expect(User.find(125283).login).to eql 'sinthetix'
    end
  end

  describe '.emails' do
    it 'finds all emails asscociated with a user' do
      expect(user.emails.first.email).to eql 'sinthetix@example.com'
    end
  end
end
