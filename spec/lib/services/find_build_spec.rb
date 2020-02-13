describe Travis::Services::FindBuild do
  let(:repo)    { FactoryBot.create(:repository, owner_name: 'travis-ci', name: 'travis-core') }
  let!(:build)  { FactoryBot.create(:build, repository: repo, state: :finished, number: 1, config: {'sudo' => false}) }
  let(:params)  { { id: build.id } }
  let(:service) { described_class.new(double('user'), params) }

  describe 'run' do
    it 'finds a build by the given id' do
      expect(service.run).to eq(build)
    end

    it 'does not raise if the build could not be found' do
      @params = { :id => build.id + 1 }
      expect { service.run }.not_to raise_error
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
    it 'returns builds updated_at attribute' do
      expect(service.updated_at.to_s).to eq(build.reload.updated_at.to_s)
    end
  end

  describe 'with newer associated record' do
    it 'returns updated_at of newest result' do
      # we're using triggers to automatically set updated_at
      # so if we want to force a give updated at we need to disable the trigger
      ActiveRecord::Base.connection.execute("ALTER TABLE builds DISABLE TRIGGER set_updated_at_on_builds;")
      build.update_attribute(:updated_at, 5.minutes.ago)
      ActiveRecord::Base.connection.execute("ALTER TABLE builds ENABLE TRIGGER set_updated_at_on_builds;")
      expect(build.reload.updated_at).to be < build.matrix.first.updated_at
      expect(service.updated_at.to_s).to eq(build.matrix.first.updated_at.to_s)
    end
  end

  describe 'without updated_at in one of the resources' do
    it 'returns updated_at of newest result' do
      allow_any_instance_of(Build).to receive(:updated_at).and_return(nil)
      expect {
        service.updated_at
      }.to_not raise_error
    end
  end

  context do
    let(:user) { FactoryBot.create(:user, login: :rkh) }
    let(:org)  { FactoryBot.create(:org, login: :travis) }
    let(:private_repo)   { FactoryBot.create(:repository, owner: org, private: true) }
    let(:public_repo)    { FactoryBot.create(:repository, owner: org, private: false) }
    let!(:private_build) { FactoryBot.create(:build, repository: private_repo, private: true) }
    let!(:public_build)  { FactoryBot.create(:build, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private build' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_build.id)
          expect(service.run).to eq(private_build)
        end

        it 'finds a public build' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_build.id)
          expect(service.run).to eq(public_build)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private build' do
          service = described_class.new(user, id: private_build.id)
          expect(service.run).to be_nil
        end

        it 'finds a public build' do
          service = described_class.new(user, id: public_build.id)
          expect(service.run).to eq(public_build)
        end
      end
    end

    describe 'private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private build' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_build.id)
          expect(service.run).to eq(private_build)
        end

        it 'finds a public build' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_build.id)
          expect(service.run).to eq(public_build)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private build' do
          service = described_class.new(user, id: private_build.id)
          expect(service.run).to be_nil
        end

        it 'does not find a public build' do
          service = described_class.new(user, id: public_build.id)
          expect(service.run).to be_nil
        end
      end
    end
  end
end
