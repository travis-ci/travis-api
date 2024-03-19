describe Broadcast do
  let(:org)  { FactoryBot.create(:org) }
  let(:repo) { FactoryBot.create(:repository) }
  let(:user) { FactoryBot.create(:user) }

  before :each do
    user.organizations << org
    user.repositories  << repo
  end

  describe 'by_user' do
    let(:broadcasts) { Broadcast.by_user(user) }

    it 'finds a global broadcast' do
      global = Broadcast.create!
      expect(broadcasts).to include(global)
    end

    it 'finds a broadcast for the given user' do
      to_user = Broadcast.create!(recipient: user, recipient_type: 'User')
      expect(broadcasts).to include(to_user)
    end

    it 'does not find a broadcast for a different user' do
      to_user = Broadcast.create!(recipient: FactoryBot.create(:user, login: 'rkh'),  recipient_type: 'User')
      expect(broadcasts).not_to include(to_user)
    end

    it 'finds a broadcast for orgs where the given user is a member' do
      to_org = Broadcast.create!(recipient: org,  recipient_type: 'Organization')
      expect(broadcasts).to include(to_org)
    end

    it 'does not find a broadcast for a different org' do
      to_org = Broadcast.create!(recipient: FactoryBot.create(:org, login: 'sinatra'))
      expect(broadcasts).not_to include(to_org)
    end

    it 'finds a broadcast for a repo where the given user has any permissions' do
      to_repo = Broadcast.create!(recipient: repo, recipient_type: 'Repository')
      expect(broadcasts).to include(to_repo)
    end

    it 'does not find a broadcast for a different repo' do
      to_repo = Broadcast.create!(recipient: FactoryBot.create(:repository, name: 'sinatra'))
      expect(broadcasts).not_to include(to_repo)
    end

    it 'does not find an expired broadcast' do
      expired = Broadcast.create!(created_at: 4.weeks.ago, expired: true)
      expect(broadcasts).not_to include(expired)
    end

    it 'does not find broadcasts older than 2 weeks' do
      too_old = Broadcast.create!(created_at: 4.weeks.ago)
      expect(broadcasts).not_to include(too_old)
    end
  end

  describe 'by_repo' do
    let(:broadcasts) { Broadcast.by_repo(repo) }

    it 'finds a global broadcast' do
      global = Broadcast.create!
      expect(broadcasts).to include(global)
    end

    it 'finds a broadcast for the given repo' do
      to_repo = Broadcast.create!(recipient: repo, recipient_type: 'Repository')
      expect(broadcasts).to include(to_repo)
    end

    it 'does not find a broadcast for a different repo' do
      to_repo = Broadcast.create!(recipient: FactoryBot.create(:repository, name: 'sinatra'), recipient_type: 'Repository')
      expect(broadcasts).not_to include(to_repo)
    end

    it 'finds a broadcast for an org this repo belongs to' do
      repo.update(owner: org, owner_type: 'Organization')
      to_org = Broadcast.create!(recipient: org,  recipient_type: 'Organization')
      expect(broadcasts).to include(to_org)
    end

    it 'does not find a broadcast for a different org' do
      repo.update(owner: org)
      to_org = Broadcast.create!(recipient: FactoryBot.create(:org, login: 'sinatra'),  recipient_type: 'Organization')
      expect(broadcasts).not_to include(to_org)
    end

    it 'finds a broadcast for a user this repo belongs to' do
      repo.update(owner: user, owner_type: 'User')
      to_org = Broadcast.create!(recipient: user,  recipient_type: 'User')
      expect(broadcasts).to include(to_org)
    end

    it 'does not find a broadcast for a different user' do
      repo.update(owner: org)
      to_org = Broadcast.create!(recipient: FactoryBot.create(:user, login: 'rkh'),  recipient_type: 'User')
      expect(broadcasts).not_to include(to_org)
    end
  end
end
