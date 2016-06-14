require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

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
    let(:user_with_organization) { create(:user, :with_organization) }

    it 'finds organization asscociated with the user' do
      expect(user_with_organization.organizations.count).to eql 1
      expect(user_with_organization.organizations.first.name).to eql 'Travis'
    end
  end

  describe '.repositories' do
    let(:user_with_repo) { create(:user, :with_repo) }

    it 'finds repositories associated with the user' do
      expect(user_with_repo.repositories.count).to eql 1
      expect(user_with_repo.repositories.first.name).to eql 'travis-admin'
    end
  end

  describe '.subscription' do
    let(:user_with_subscription) { create(:user, :with_subscription) }

    it 'finds the subscription associated with the user' do
      expect(user_with_subscription.subscription).not_to be nil
      expect(user_with_subscription.subscription.owner_id).to eql user_with_subscription.id
    end
  end
end
