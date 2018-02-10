describe Travis::Services::FindRepos do
  before { DatabaseCleaner.clean_with :truncation }

  let(:user) { Factory(:user) }
  let!(:repo)   { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core', :active => true) }
  let(:service) { described_class.new(user, params) }

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

  context do
    let(:user) { Factory.create(:user, login: :rkh) }
    let(:org)  { Factory.create(:org, login: :travis) }
    let(:private_repo) { Factory.create(:repository, owner: org, private: true) }
    let(:public_repo)  { Factory.create(:repository, owner: org, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private repository' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_repo.id)
          service.run.should include(private_repo)
        end

        it 'finds a public repository' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_repo.id)
          service.run.should include(public_repo)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private repository' do
          service = described_class.new(user, id: private_repo.id)
          service.run.should_not include(private_repo)
        end

        it 'finds a public repository' do
          service = described_class.new(user, id: public_repo.id)
          service.run.should include(public_repo)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private repository' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_repo.id)
          service.run.should include(private_repo)
        end

        it 'finds a public repository' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_repo.id)
          service.run.should include(public_repo)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private repository' do
          service = described_class.new(user, id: private_repo.id)
          service.run.should_not include(private_repo)
        end

        it 'does not find a public repository' do
          service = described_class.new(user, id: public_repo.id)
          service.run.should_not include(public_repo)
        end
      end
    end
  end
end
