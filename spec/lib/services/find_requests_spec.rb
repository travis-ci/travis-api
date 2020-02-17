describe Travis::Services::FindRequests do
  let(:user) { FactoryBot.create(:user) }
  let(:repo) { FactoryBot.create(:repository, :owner_name => 'travis-ci', :name => 'travis-core') }
  let!(:request)  { FactoryBot.create(:request, :repository => repo) }
  let!(:newer_request)  { FactoryBot.create(:request, :repository => repo) }
  let(:service) { described_class.new(user, params) }

  attr_reader :params

  describe 'run' do
    it 'finds recent requests when older_than is not given' do
      @params = { :repository_id => repo.id }
      expect(service.run).to match_array([newer_request, request])
    end

    it 'includes the build_id' do
      FactoryBot.create(:build, request_id: request.id)
      @params = { :repository_id => repo.id }
      requests = service.run
      expect(requests).to match_array([newer_request, request])
      requests.first.build_id  = nil
      requests.second.build_id = request.builds.first.id
    end

    it 'finds requests older than the given id' do
      @params = { :repository_id => repo.id, :older_than => newer_request.id }
      expect(service.run).to eq([request])
    end

    it 'raises an error if repository params are missing' do
      @params = { }
      expect {
        service.run
      }.to raise_error(Travis::RepositoryNotFoundError, "Repository could not be found")
    end

    it 'scopes to the given repository_id' do
      @params = { :repository_id => repo.id }
      FactoryBot.create(:request, :repository => FactoryBot.create(:repository))
      expect(service.run).to match_array([newer_request, request])
    end

    it 'raises when the repository could not be found' do
      @params = { :repository_id => repo.id + 1 }
      expect {
        service.run
      }.to raise_error(Travis::RepositoryNotFoundError, "Repository with id=#{repo.id + 1} could not be found")
    end

    it 'limits requests if limit is passed' do
      @params = { :repository_id => repo.id, :limit => 1 }
      expect(service.run).to eq([newer_request])
    end

    it 'limits requests to Travis.config.services.find_requests.max_limit if limit is higher' do
      previous_limit = Travis.config.services.find_requests.max_limit
      Travis.config.services.find_requests.max_limit = 1
      @params = { :repository_id => repo.id, :limit => 2 }
      expect(service.run).to eq([newer_request])
      Travis.config.services.find_requests.max_limit = previous_limit
    end

    it 'limits requests to Travis.config.services.find_requests.default_limit if limit is not given' do
      previous_limit = Travis.config.services.find_requests.default_limit
      Travis.config.services.find_requests.default_limit = 1
      @params = { :repository_id => repo.id }
      expect(service.run).to eq([newer_request])
      Travis.config.services.find_requests.default_limit = previous_limit
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
          service = described_class.new(user, repository_id: private_repo.id)
          expect(service.run).to include(private_request)
        end

        it 'finds a public request' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, repository_id: public_repo.id)
          expect(service.run).to include(public_request)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, repository_id: private_repo.id)
          expect { service.run }.to raise_error(Travis::RepositoryNotFoundError)
        end

        it 'finds a public request' do
          service = described_class.new(user, repository_id: public_repo.id)
          expect(service.run).to include(public_request)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private request' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, repository_id: private_repo.id)
          expect(service.run).to include(private_request)
        end

        it 'finds a public request' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, repository_id: public_repo.id)
          expect(service.run).to include(public_request)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private request' do
          service = described_class.new(user, repository_id: private_repo.id)
          expect { service.run }.to raise_error(Travis::RepositoryNotFoundError)
        end

        it 'does not find a public request' do
          service = described_class.new(user, repository_id: public_repo.id)
          expect { service.run }.to raise_error(Travis::RepositoryNotFoundError)
        end
      end
    end
  end
end
