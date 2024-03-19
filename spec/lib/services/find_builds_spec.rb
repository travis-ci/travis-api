describe Travis::Services::FindBuilds do
  before { DatabaseCleaner.clean_with :truncation }

  let(:user)    { FactoryBot.create(:user) }
  let(:repo)    { FactoryBot.create(:repository_without_last_build, owner_name: 'travis-ci', name: 'travis-core') }
  let!(:push)   { FactoryBot.create(:build, repository: repo, event_type: 'push', state: :failed, number: 1) }
  let(:service) { described_class.new(user, params) }

  attr_reader :params

  describe 'run' do
    it 'finds recent builds when empty params given' do
      @params = { :repository_id => repo.id }
      expect(service.run).to eq([push])
    end

    it 'finds running builds when running param is passed' do
      running = FactoryBot.create(:build, repository: repo, event_type: 'push', state: 'started', number: 2)
      @params = { :running => true }
      expect(service.run).to eq([running])
    end

    it 'finds no recent builds when no repo given' do
      @params = nil
      expect(service.run).to eq([])
    end

    it 'finds builds older than the given number' do
      @params = { :repository_id => repo.id, :after_number => 2 }
      expect(service.run).to eq([push])
    end

    it 'finds builds with a given number, scoped by repository' do
      @params = { :repository_id => repo.id, :number => 1 }
      FactoryBot.create(:build, :repository => FactoryBot.create(:repository_without_last_build), :state => :finished, :number => 1)
      FactoryBot.create(:build, :repository => repo, :state => :finished, :number => 2)
      expect(service.run).to eq([push])
    end

    it 'does not find by number if repository_id is missing' do
      @params = { :number => 1 }
      expect(service.run.empty?).to be_truthy
    end

    it 'scopes to the given repository_id' do
      @params = { :repository_id => repo.id }
      FactoryBot.create(:build, :repository => FactoryBot.create(:repository_without_last_build), :state => :finished)
      expect(service.run).to eq([push])
    end

    it 'returns an empty build scope when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      expect(service.run.empty?).to be_truthy
    end

    it 'finds builds by a given list of ids' do
      @params = { :ids => [push.id] }
      expect(service.run).to eq([push])
    end

    describe 'finds recent builds when event_type' do
      let!(:pull_request) { FactoryBot.create(:build, repository: repo, state: :finished, number: 2, request: FactoryBot.create(:request, :event_type => 'pull_request')) }
      let!(:api)          { FactoryBot.create(:build, repository: repo, state: :finished, number: 2, request: FactoryBot.create(:request, :event_type => 'api')) }

      it 'given as push' do
        @params = { repository_id: repo.id, event_type: 'push' }
        expect(service.run).to eq([push])
      end

      it 'given as pull_request' do
        @params = { repository_id: repo.id, event_type: 'pull_request' }
        expect(service.run).to eq([pull_request])
      end

      it 'given as api' do
        @params = { repository_id: repo.id, event_type: 'api' }
        expect(service.run).to eq([api])
      end

      it 'given as [push, api]' do
        @params = { repository_id: repo.id, event_type: ['push', 'api'] }
        expect(service.run.sort).to eq([push, api])
      end
    end
  end

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:org)  { FactoryBot.create(:org, login: :travis) }
    let(:private_repo)   { FactoryBot.create(:repository, owner: org, private: true) }
    let(:public_repo)    { FactoryBot.create(:repository, owner: org, private: false) }

    let(:private_repo_branch)    { Branch.find_by(repository_id: private_repo.id, name: 'master') }
    let(:public_repo_branch)    { Branch.find_by(repository_id: public_repo.id, name: 'master') }
    let!(:private_build) { FactoryBot.create(:build, repository: private_repo, private: true, branch: private_repo_branch) }
    let!(:public_build)  { FactoryBot.create(:build, repository: public_repo, private: false, branch: public_repo_branch) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private build' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user)
          expect(service.run).to include(private_build)
        end

        it 'finds a public build' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user)
          expect(service.run).to include(public_build)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private build' do
          service = described_class.new(user)
          expect(service.run).not_to include(private_build)
        end

        it 'does not fine a public build' do
          service = described_class.new(user)
          expect(service.run).not_to include(public_build)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private build' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user)
          expect(service.run).to include(private_build)
        end

        it 'finds a public build' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user)
          expect(service.run).to include(public_build)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private build' do
          service = described_class.new(user)
          expect(service.run).not_to include(private_build)
        end

        it 'does not find a public build' do
          service = described_class.new(user)
          expect(service.run).not_to include(public_build)
        end
      end
    end
  end

  context 'on .com with public mode' do
    before do
      Travis.config.public_mode = true
      Travis.config.host = "travis-ci.com"
    end
    after { Travis.config.host = "travis-ci.org" }

    it "doesn't return public builds that don't belong to a user" do
      public_repo = FactoryBot.create(:repository_without_last_build, :owner_name => 'foo', :name => 'bar', private: false)
      public_build = FactoryBot.create(:build, repository: public_repo)
      FactoryBot.create(:test, :state => :started, :source => public_build, repository: public_repo)

      user = FactoryBot.create(:user)
      repo = FactoryBot.create(:repository_without_last_build, :owner_name => 'drogus', :name => 'test-project')
      repo.users << user
      build = FactoryBot.create(:build, repository: repo)
      job = FactoryBot.create(:test, :state => :started, :source => build, repository: repo)

      other_user = FactoryBot.create(:user)
      other_repo = FactoryBot.create(:repository_without_last_build, private: true)
      other_repo.users << other_user
      other_build = FactoryBot.create(:build, repository: other_repo)
      FactoryBot.create(:test, :state => :started, :source => other_build, repository: other_repo)

      service = described_class.new(user)
      expect(service.run).to eq([build])
    end
  end
end
