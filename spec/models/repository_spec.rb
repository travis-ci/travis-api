require 'rails_helper'

RSpec.describe Repository, type: :model do
  describe '#slug' do
    let!(:repository) { create(:repository, owner_name: 'travis') }

    it 'combines owner_name with repository name' do
      expect(repository.slug).to eql 'travis/travis-admin'
    end
  end

  describe '#permissions_sorted' do
    let!(:repository_with_users) { create(:repo_with_users) }

    it 'returns Hash with users sorted according to their permissions' do
      expect(repository_with_users.permissions_sorted).to be_a(Hash)

      expect(repository_with_users.permissions_sorted[:admin]).to be_a(Array)
      expect(repository_with_users.permissions_sorted[:admin]).not_to be_empty

      expect(repository_with_users.permissions_sorted[:pull]).to be_a(Array)
      expect(repository_with_users.permissions_sorted[:pull]).not_to be_empty

      expect(repository_with_users.permissions_sorted[:push]).to be_a(Array)
      expect(repository_with_users.permissions_sorted[:push]).not_to be_empty
    end

    it 'contains an Array with all admin users' do
      user = repository_with_users.permissions_sorted[:admin].first
      expect(user.permissions.first.admin?).to be true
    end

    it 'contains an Array with all pull access users' do
      user = repository_with_users.permissions_sorted[:pull].first
      expect(user.permissions.first.pull?).to be true
    end

    it 'contains an Array with all push access users' do
      user = repository_with_users.permissions_sorted[:push].first
      expect(user.permissions.first.push?).to be true
    end
  end
end
