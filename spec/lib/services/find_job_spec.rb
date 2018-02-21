describe Travis::Services::FindJob do
  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, repository: repo, state: :created, queue: 'builds.linux', config: {'sudo' => false}) }
  let(:params)  { { id: job.id } }
  let(:service) { described_class.new(stub('user'), params) }

  describe 'run' do
    it 'finds the job with the given id' do
      @params = { id: job.id }
      service.run.should == job
    end

    it 'does not raise if the job could not be found' do
      @params = { id: job.id + 1 }
      lambda { service.run }.should_not raise_error
    end

    it 'raises RecordNotFound if a SubclassNotFound error is raised during find' do
      find_by_id = stub.tap do |s|
        s.stubs(:column_names).returns(%w(id config))
        s.stubs(:includes).returns(s)
        s.stubs(:select).returns(s)
        s.stubs(:find_by_id).raises(ActiveRecord::SubclassNotFound)
      end
      service.stubs(:scope).returns(find_by_id)
      lambda { service.run }.should raise_error(ActiveRecord::RecordNotFound)
    end

    it 'includes config by default' do
      service.run.config.should include(:sudo)
    end

    it 'excludes config when requested' do
      params[:exclude_config] = '1'
      service.run.config.should_not include(:sudo)
    end
  end

  describe 'updated_at' do
    it 'returns jobs updated_at attribute' do
      service.updated_at.to_s.should == job.reload.updated_at.to_s
    end
  end

  context do
    let(:user) { Factory.create(:user, login: :rkh) }
    let(:org)  { Factory.create(:org, login: :travis) }
    let(:private_repo) { Factory.create(:repository, owner: org, private: true) }
    let(:public_repo)  { Factory.create(:repository, owner: org, private: false) }
    let!(:private_job) { Factory.create(:job, repository: private_repo, private: true) }
    let!(:public_job)  { Factory.create(:job, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          service.run.should == private_job
        end

        it 'finds a public job' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          service.run.should == public_job
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          service.run.should be_nil
        end

        it 'finds a public job' do
          service = described_class.new(user, id: public_job.id)
          service.run.should == public_job
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.private_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          service.run.should == private_job
        end

        it 'finds a public job' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          service.run.should == public_job
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          service.run.should be_nil
        end

        it 'does not find a public job' do
          service = described_class.new(user, id: public_job.id)
          service.run.should == public_job
        end
      end
    end
  end
end
