describe Travis::Services::FindJob do
  let(:repo)    { FactoryBot.create(:repository) }
  let!(:job)    { FactoryBot.create(:test, repository: repo, state: :created, owner_type: 'User', queue: 'builds.linux', config: {'sudo' => false}) }
  let(:params)  { { id: job.id } }
  let(:service) { described_class.new(double('user'), params) }

  describe 'run' do
    it 'finds the job with the given id' do
      @params = { id: job.id }
      expect(service.run).to eq(job)
    end

    it 'does not raise if the job could not be found' do
      @params = { id: job.id + 1 }
      expect { service.run }.not_to raise_error
    end

    it 'raises RecordNotFound if a SubclassNotFound error is raised during find' do
      find_by_id = double.tap do |s|
        allow(s).to receive(:column_names).and_return(%w(id config))
        allow(s).to receive(:includes).and_return(s)
        allow(s).to receive(:select).and_return(s)
        allow(s).to receive(:find_by_id).and_raise(ActiveRecord::SubclassNotFound)
      end
      allow(service).to receive(:scope).and_return(find_by_id)
      expect { service.run }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'includes config by default' do
      expect(service.run.config).to include(:sudo)
    end

    it 'excludes config when requested' do
      params[:exclude_config] = '1'
      expect(service.run.config).not_to include(:sudo)
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      expect(service.updated_at.to_s).to eq(job.reload.updated_at.to_s)
    end
  end

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:org)  { FactoryBot.create(:org, login: :travis) }
    let(:private_repo) { FactoryBot.create(:repository, owner: org, private: true) }
    let(:public_repo)  { FactoryBot.create(:repository, owner: org, private: false) }
    let!(:private_job) { FactoryBot.create(:job, repository: private_repo, private: true) }
    let!(:public_job)  { FactoryBot.create(:job, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          expect(service.run).to eq(private_job)
        end

        it 'finds a public job' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to eq(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          expect(service.run).to be_nil
        end

        it 'finds a public job' do
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to eq(public_job)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.private_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          expect(service.run).to eq(private_job)
        end

        it 'finds a public job' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to eq(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          expect(service.run).to be_nil
        end

        it 'does not find a public job' do
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to eq(public_job)
        end
      end
    end
  end
end
