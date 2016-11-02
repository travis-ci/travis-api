require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:user) { create(:user) }
  let!(:email) { create(:email, user: user) }

  describe '.login' do
    it 'retrieves login name' do
      expect(user.login).to eql 'travisbot'
    end
  end

  describe '.email' do
    it 'retrieves primary email address' do
      expect(user.email).to eql 'travis@example.com'
    end
  end

  describe '.emails' do
    it 'finds additional email associated with a user' do
      expect(user.emails.first.email).to eql 'example@example.com'
    end
  end

  describe '.organizations' do
    let(:user_with_organizations) { create(:user_with_organizations) }

    it 'finds organizations associated with the user' do
      expect(user_with_organizations.organizations.count).to eql 2
      expect(user_with_organizations.organizations.first.name).to eql 'Travis'
    end
  end

  describe '.repositories' do
    let(:user_with_repos) { create(:user_with_repositories) }

    it 'finds repositories user ownes' do
      expect(user_with_repos.repositories.count).to eql 2
      expect(user_with_repos.repositories.first.name).to eql 'travis-admin'
    end
  end

  describe '.permitted_repositories' do
    let!(:user_with_repo) { create(:user_with_repository) }
    let!(:user_with_repo_through_organization) { create(:user_with_repo_through_organization) }

    it 'finds repository user ownes' do
      expect(user_with_repo.permitted_repositories.count).to eql 1
      expect(user_with_repo.permitted_repositories.first.name).to eql 'travis-admin'
    end

    it 'finds repositories associated with user through organizations' do
      expect(user_with_repo_through_organization.permitted_repositories.count).to eql 1
      expect(user_with_repo_through_organization.permitted_repositories.first.name).to eql 'emerald'
    end
  end

  describe '.subscription' do
    let(:user_with_subscription) { create(:user_with_active_subscription) }

    it 'finds the subscription associated with the user' do
      expect(user_with_subscription.subscription).not_to be nil
      expect(user_with_subscription.subscription.owner_id).to eql user_with_subscription.id
    end
  end
end
