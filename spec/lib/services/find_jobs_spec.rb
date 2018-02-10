describe Travis::Services::FindJobs do
  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, :repository => repo, :state => :created, :queue => 'builds.linux') }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds jobs on the given queue' do
      @params = { :queue => 'builds.linux' }
      service.run.should include(job)
    end

    it 'does not find jobs on other queues' do
      @params = { :queue => 'builds.nodejs' }
      service.run.should_not include(job)
    end

    it 'finds jobs by a given list of ids' do
      @params = { :ids => [job.id] }
      service.run.should == [job]
    end

    it 'finds jobs by state' do
      build = Factory(:build)

      Job::Test.destroy_all

      started = Factory(:test, :state => :started, :source => build)
      passed  = Factory(:test, :state => :passed,  :source => build)
      created = Factory(:test, :state => :created, :source => build)

      @params = { :state => ['created', 'passed'] }
      service.run.sort_by(&:id).should == [created, passed].sort_by(&:id)
    end

    it 'finds jobs that are about to run without any args' do
      build = Factory(:build)

      Job::Test.destroy_all

      started = Factory(:test, :state => :started, :source => build)
      queued = Factory(:test, :state => :queued, :source => build)
      passed  = Factory(:test, :state => :passed,  :source => build)
      created = Factory(:test, :state => :created, :source => build)
      received = Factory(:test, :state => :received, :source => build)

      @params = {}
      service.run.sort_by(&:id).should == [started, queued, created, received].sort_by(&:id)
    end
  end

  describe 'updated_at' do
    it 'returns the latest updated_at time' do
      skip 'rack cache is disabled, so not much need for caching now'

      @params = { :queue => 'builds.linux' }
      Job.delete_all
      Factory(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now - 1.hour)
      Factory(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now)
      service.updated_at.to_s.should == Time.now.to_s
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
          service.run.should include(private_job)
        end

        it 'finds a public job' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          service.run.should include(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          service.run.should_not include(private_job)
        end

        it 'finds a public job' do
          service = described_class.new(user, id: public_job.id)
          service.run.should include(public_job)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          Factory.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          service.run.should include(private_job)
        end

        it 'finds a public job' do
          Factory.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          service.run.should include(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          service.run.should_not include(private_job)
        end

        it 'does not find a public job' do
          service = described_class.new(user, id: public_job.id)
          service.run.should_not include(public_job)
        end
      end
    end
  end
end
