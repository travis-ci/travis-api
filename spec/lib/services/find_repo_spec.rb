describe Travis::Services::FindRepo do

  let(:user) { FactoryBot.create(:user) }
  let!(:repo)   { FactoryBot.create(:repository_without_last_build, :owner => user, :owner_name => 'travis-ci', :name => 'travis-core') }
  let(:service) { described_class.new(user, params) }

  attr_reader :params

  describe 'run' do
    it 'finds a repository by the given id' do
      @params = { :id => repo.id }
      expect(service.run).to eq(repo)
    end

    it 'finds a repository by the given owner_name and name' do
      @params = { :owner_name => repo.owner_name, :name => repo.name }
      expect(service.run).to eq(repo)
    end

    it 'does not raise if the repository could not be found' do
      @params = { :id => repo.id + 1 }
      expect { service.run }.not_to raise_error
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      @params = { :id => repo.id }
      expect(service.updated_at.to_s).to eq(repo.updated_at.to_s)
    end
  end

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:org)  { FactoryBot.create(:org, login: :travis) }
    let(:private_repo) { FactoryBot.create(:repository, owner: org, private: true) }
    let(:public_repo)  { FactoryBot.create(:repository, owner: org, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private repository' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_repo.id)
          expect(service.run).to eq(private_repo)
        end

        it 'finds a public repository' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_repo.id)
          expect(service.run).to eq(public_repo)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private repository' do
          service = described_class.new(user, id: private_repo.id)
          expect(service.run).to be_nil
        end

        it 'finds a public repository' do
          service = described_class.new(user, id: public_repo.id)
          expect(service.run).to eq(public_repo)
        end
      end
    end

    describe 'private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do

        it 'finds a private repository' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_repo.id)
          expect(service.run).to eq(private_repo)
        end

        it 'finds a public repository' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_repo.id)
          expect(service.run).to eq(public_repo)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private repository' do
          service = described_class.new(user, id: private_repo.id)
          expect(service.run).to be_nil
        end

        it 'does not find a public repository'  do
          service = described_class.new(user, id: public_repo.id)
          expect(service.run).to be_nil
        end
      end
    end
  end
end
