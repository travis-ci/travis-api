describe Travis::Services::FindBranches do
  describe 'on org' do
    let(:user)    { FactoryBot.create(:user) }
    let(:repo)    { FactoryBot.create(:repository_without_last_build, :owner_name => 'travis-ci', :name => 'travis-core') }
    let!(:build)  { FactoryBot.create(:build, :repository => repo, :state => :finished) }
    let(:service) { described_class.new(user, params) }

    attr_reader :params

    before { Travis.config.host = 'travis-ci.org' }

    it 'finds the last builds of the given repository grouped per branch' do
      @params = { :repository_id => repo.id }
      expect(service.run).to include(build)
    end

    it 'scopes to the given repository' do
      @params = { :repository_id => repo.id }
      build = FactoryBot.create(:build, :repository => FactoryBot.create(:repository_without_last_build), :state => :finished)
      expect(service.run).not_to include(build)
    end

    it 'returns an empty build scope when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      expect(service.run.empty?).to be_truthy
    end

    it 'finds branches by a given list of ids' do
      @params = { :ids => [build.id] }
      expect(service.run).to eq([build])
    end
  end

  let(:user) { FactoryBot.create(:user, login: :rkh) }
  let(:org)  { FactoryBot.create(:org, login: :travis) }
  let(:private_repo)   { FactoryBot.create(:repository_without_last_build, owner: org, private: true) }
  let(:public_repo)    { FactoryBot.create(:repository_without_last_build, owner: org, private: false) }
  let!(:private_build) { FactoryBot.create(:build, repository: private_repo, private: true) }
  let!(:public_build)  { FactoryBot.create(:build, repository: public_repo, private: false) }

  before { Travis.config.host = 'example.com' }

  describe 'in public mode' do
    before { Travis.config.public_mode = true }

    describe 'given the current user has a permission on the repository' do
      it 'finds a private build' do
        FactoryBot.create(:permission, user: user, repository: private_repo)
        service = described_class.new(user, repository_id: private_repo.id)
        expect(service.run).to include(private_build)
      end

      it 'finds a public build' do
        FactoryBot.create(:permission, user: user, repository: public_repo)
        service = described_class.new(user, repository_id: public_repo.id)
        expect(service.run).to include(public_build)
      end
    end

    describe 'given the current user does not have a permission on the repository' do
      it 'does not find a private build' do
        service = described_class.new(user, repository_id: private_repo.id)
        expect(service.run).not_to include(public_build)
      end

      it 'finds a public build' do
        service = described_class.new(user, repository_id: public_repo.id)
        expect(service.run).to include(public_build)
      end
    end
  end

  describe 'in private mode' do
    before { Travis.config.public_mode = false }

    describe 'given the current user has a permission on the repository' do
      it 'finds a private build' do
        FactoryBot.create(:permission, user: user, repository: private_repo)
        service = described_class.new(user, repository_id: private_repo.id)
        expect(service.run).to include(private_build)
      end

      it 'finds a public build' do
        FactoryBot.create(:permission, user: user, repository: public_repo)
        service = described_class.new(user, repository_id: public_repo.id)
        expect(service.run).to include(public_build)
      end
    end

    describe 'given the current user does not have a permission on the repository' do
      it 'does not find a private build' do
        service = described_class.new(user, repository_id: private_repo.id)
        expect(service.run).not_to include(public_build)
      end

      it 'does not find a public build' do
        service = described_class.new(user, repository_id: public_repo.id)
        expect(service.run).not_to include(public_build)
      end
    end
  end
end
