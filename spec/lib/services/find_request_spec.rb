describe Travis::Services::FindRequest do
  let(:repo)    { FactoryBot.create(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { FactoryBot.create(:request, :repository => repo) }
  let(:params)  { { :id => request.id } }
  let(:service) { described_class.new(double('user'), params) }

  describe 'run' do
    it 'finds a request by the given id' do
      expect(service.run).to eq(request)
    end

    it 'does not raise if the request could not be found' do
      @params = { :id => request.id + 1 }
      expect { service.run }.not_to raise_error
    end
  end

  describe 'updated_at' do
    it 'returns request\'s updated_at attribute' do
      expect(service.updated_at.to_s).to eq(request.updated_at.to_s)
    end
  end

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:org)  { FactoryBot.create(:org, login: :travis) }
    let(:private_repo) { FactoryBot.create(:repository, owner: org, private: true) }
    let(:public_repo)  { FactoryBot.create(:repository, owner: org, private: false) }
    let(:private_request) { FactoryBot.create(:request, repository: private_repo, private: true) }
    let(:public_request)  { FactoryBot.create(:request, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private request' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_request.id)
          expect(service.run).to eq(private_request)
        end

        it 'finds a public request' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_request.id)
          expect(service.run).to eq(public_request)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, id: private_request.id)
          expect(service.run).to be_nil
        end

        it 'finds a public request' do
          service = described_class.new(user, id: public_request.id)
          expect(service.run).to eq(public_request)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private request' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_request.id)
          expect(service.run).to eq(private_request)
        end

        it 'finds a public request' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_request.id)
          expect(service.run).to eq(public_request)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, id: private_request.id)
          expect(service.run).to be_nil
        end

        it 'does not find a public request' do
          service = described_class.new(user, id: public_request.id)
          expect(service.run).to be_nil
        end
      end
    end
  end
end
