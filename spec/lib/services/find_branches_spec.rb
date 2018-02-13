describe Travis::Services::FindBranches do
  describe 'on org' do
    let(:user)    { Factory(:user) }
    let(:repo)    { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
    let!(:build)  { Factory(:build, :repository => repo, :state => :finished) }
    let(:service) { described_class.new(user, params) }

    attr_reader :params

    before { Travis.config.host = 'travis-ci.org' }

    it 'finds the last builds of the given repository grouped per branch' do
      @params = { :repository_id => repo.id }
      service.run.should include(build)
    end

    it 'scopes to the given repository' do
      @params = { :repository_id => repo.id }
      build = Factory(:build, :repository => Factory(:repository), :state => :finished)
      service.run.should_not include(build)
    end

    it 'returns an empty build scope when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      service.run.should == Build.none
    end

    it 'finds branches by a given list of ids' do
      @params = { :ids => [build.id] }
      service.run.should == [build]
    end
  end

  let(:user) { Factory.create(:user, login: :rkh) }
  let(:org)  { Factory.create(:org, login: :travis) }
  let(:private_repo)   { Factory.create(:repository, owner: org, private: true) }
  let(:public_repo)    { Factory.create(:repository, owner: org, private: false) }
  let!(:private_build) { Factory.create(:build, repository: private_repo, private: true) }
  let!(:public_build)  { Factory.create(:build, repository: public_repo, private: false) }

  before { Travis.config.host = 'example.com' }

  describe 'in public mode' do
    before { Travis.config.public_mode = true }

    describe 'given the current user has a permission on the repository' do
      it 'finds a private build' do
        Factory.create(:permission, user: user, repository: private_repo)
        service = described_class.new(user, repository_id: private_repo.id)
        service.run.should include(private_build)
      end

      it 'finds a public build' do
        Factory.create(:permission, user: user, repository: public_repo)
        service = described_class.new(user, repository_id: public_repo.id)
        service.run.should include(public_build)
      end
    end

    describe 'given the current user does not have a permission on the repository' do
      it 'does not find a private build' do
        service = described_class.new(user, repository_id: private_repo.id)
        service.run.should_not include(public_build)
      end

      it 'finds a public build' do
        service = described_class.new(user, repository_id: public_repo.id)
        service.run.should include(public_build)
      end
    end
  end

  describe 'in private mode' do
    before { Travis.config.public_mode = false }

    describe 'given the current user has a permission on the repository' do
      it 'finds a private build' do
        Factory.create(:permission, user: user, repository: private_repo)
        service = described_class.new(user, repository_id: private_repo.id)
        service.run.should include(private_build)
      end

      it 'finds a public build' do
        Factory.create(:permission, user: user, repository: public_repo)
        service = described_class.new(user, repository_id: public_repo.id)
        service.run.should include(public_build)
      end
    end

    describe 'given the current user does not have a permission on the repository' do
      it 'does not find a private build' do
        service = described_class.new(user, repository_id: private_repo.id)
        service.run.should_not include(public_build)
      end

      it 'does not find a public build' do
        service = described_class.new(user, repository_id: public_repo.id)
        service.run.should_not include(public_build)
      end
    end
  end
end
