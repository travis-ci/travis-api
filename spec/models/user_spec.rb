require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { FactoryGirl.create(:user) }

  describe '.find' do
    it 'finds user by ID' do
      expect(user.find(125283)).to_not be_nil
    end

    it 'retrieves login name' do
      expect(user.find(125283).login).to eql 'sinthetix'
    end
  end
end
