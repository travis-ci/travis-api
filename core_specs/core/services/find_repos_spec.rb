require 'spec_helper'

describe Travis::Services::FindRepos do
  include Support::ActiveRecord

  let!(:repo)   { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core', :active => true) }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  it 'limits the repositories list' do
    Factory(:repository)
    @params = { :limit => 1 }
    service.run.length.should == 1
  end

  it 'ignores the limit if it is not a number' do
    Factory(:repository)
    @params = { :limit => 'a' }
    service.run.length.should == 2
  end

  it 'does not allow for limit higher than 50' do
    @params = { :limit => 60 }
    service.send(:limit).should == 50
  end

  it 'finds repositories by a given list of ids' do
    @params = { :ids => [repo.id] }
    service.run.should == [repo]
  end

  it 'returns the recent timeline when given empty params' do
    @params = {}
    service.run.should include(repo)
  end

  it 'applies timeline only if no other params are given' do
    repo = Factory(:repository, :owner_name => 'foo', :name => 'bar', :last_build_started_at => nil, :active => true)
    @params = { slug: 'foo/bar' }
    service.run.should include(repo)
  end

  describe 'given a member name' do
    it 'finds a repository where that member has permissions' do
      @params = { :member => 'joshk' }
      repo.users << Factory(:user, :login => 'joshk')
      service.run.should include(repo)
    end

    it 'does not find a repository where the member does not have permissions' do
      @params = { :member => 'joshk' }
      service.run.should_not include(repo)
    end

    # TODO ... we now include all :active repos (i.e. including those that haven't built yet)
    # and last_build_started_at is nil for them, too. since there's no easy way to detect
    # queued builds on the repo timeline i'm just disabling this for now.
    #
    # it 'sorts by latest build, putting queued (no last_build_started_at) at the front' do
    #   repo.update_column(:last_build_started_at, Time.now - 10)
    #   queued = Factory(:repository, name: 'queued', last_build_started_at: nil, :active => true)
    #   just_started = Factory(:repository,  name: 'just-started',last_build_started_at: Time.now, :active => true)
    #   josh = Factory(:user, :login => 'joshk')
    #   [repo, queued, just_started].each { |r| r.users << josh }
    #   @params = { :member => 'joshk' }
    #   service.run.map(&:name).should == [queued, just_started, repo].map(&:name)
    # end
  end

  describe 'given an owner_name name' do
    it 'finds a repository with that owner_name' do
      @params = { :owner_name => 'travis-ci' }
      service.run.should include(repo)
    end

    it 'does not find a repository with another owner name' do
      @params = { :owner_name => 'sinatra' }
      service.run.should_not include(repo)
    end
  end

  describe 'given an owner_name name and active param' do
    it 'finds a repository with that owner_name even if it does not have any builds' do
      repo.update_column(:last_build_id, nil)
      repo.update_column(:active, true)
      @params = { :owner_name => 'travis-ci', :active => true }
      service.run.should include(repo)
    end
  end

  describe 'given a slug name' do
    it 'finds a repository with that slug' do
      @params = { :slug => 'travis-ci/travis-core' }
      service.run.should include(repo)
    end

    it 'does not find a repository with a different slug' do
      @params = { :slug => 'travis-ci/travis-hub' }
      service.run.should_not include(repo)
    end
  end

  describe 'given a search phrase' do
    it 'finds a repository matching that phrase' do
      @params = { :search => 'travis' }
      service.run.should include(repo)
    end

    it 'does not find a repository that does not match that phrase' do
      @params = { :search => 'sinatra' }
      service.run.should_not include(repo)
    end
  end

  describe 'given a list of ids' do
    it 'finds included repositories' do
      @params = { :ids => [repo.id] }
      service.run.should include(repo)
    end

    it 'does not find a repositories that are not included' do
      @params = { :ids => [repo.id + 1] }
      service.run.should_not include(repo)
    end
  end
end
