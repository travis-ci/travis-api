require 'spec_helper'

describe Broadcast do
  include Support::ActiveRecord

  let(:org)  { Factory(:org) }
  let(:repo) { Factory(:repository) }
  let(:user) { Factory(:user) }

  before :each do
    user.organizations << org
    user.repositories  << repo
  end

  describe 'by_user' do
    let(:broadcasts) { Broadcast.by_user(user) }

    it 'finds a global broadcast' do
      global = Broadcast.create!
      broadcasts.should include(global)
    end

    it 'finds a broadcast for the given user' do
      to_user = Broadcast.create!(recipient: user)
      broadcasts.should include(to_user)
    end

    it 'does not find a broadcast for a different user' do
      to_user = Broadcast.create!(recipient: Factory(:user, login: 'rkh'))
      broadcasts.should_not include(to_user)
    end

    it 'finds a broadcast for orgs where the given user is a member' do
      to_org = Broadcast.create!(recipient: org)
      broadcasts.should include(to_org)
    end

    it 'does not find a broadcast for a different org' do
      to_org = Broadcast.create!(recipient: Factory(:org, login: 'sinatra'))
      broadcasts.should_not include(to_org)
    end

    it 'finds a broadcast for a repo where the given user has any permissions' do
      to_repo = Broadcast.create!(recipient: repo)
      broadcasts.should include(to_repo)
    end

    it 'does not find a broadcast for a different repo' do
      to_repo = Broadcast.create!(recipient: Factory(:repository, name: 'sinatra'))
      broadcasts.should_not include(to_repo)
    end

    it 'does not find an expired broadcast' do
      expired = Broadcast.create!(created_at: 4.weeks.ago, expired: true)
      broadcasts.should_not include(expired)
    end

    it 'does not find broadcasts older than 2 weeks' do
      too_old = Broadcast.create!(created_at: 4.weeks.ago)
      broadcasts.should_not include(too_old)
    end
  end

  describe 'by_repo' do
    let(:broadcasts) { Broadcast.by_repo(repo) }

    it 'finds a global broadcast' do
      global = Broadcast.create!
      broadcasts.should include(global)
    end

    it 'finds a broadcast for the given repo' do
      to_repo = Broadcast.create!(recipient: repo)
      broadcasts.should include(to_repo)
    end

    it 'does not find a broadcast for a different repo' do
      to_repo = Broadcast.create!(recipient: Factory(:repository, name: 'sinatra'))
      broadcasts.should_not include(to_repo)
    end

    it 'finds a broadcast for an org this repo belongs to' do
      repo.update_attributes(owner: org)
      to_org = Broadcast.create!(recipient: org)
      broadcasts.should include(to_org)
    end

    it 'does not find a broadcast for a different org' do
      repo.update_attributes(owner: org)
      to_org = Broadcast.create!(recipient: Factory(:org, login: 'sinatra'))
      broadcasts.should_not include(to_org)
    end

    it 'finds a broadcast for a user this repo belongs to' do
      repo.update_attributes(owner: user)
      to_org = Broadcast.create!(recipient: user)
      broadcasts.should include(to_org)
    end

    it 'does not find a broadcast for a different user' do
      repo.update_attributes(owner: org)
      to_org = Broadcast.create!(recipient: Factory(:user, login: 'rkh'))
      broadcasts.should_not include(to_org)
    end
  end
end
