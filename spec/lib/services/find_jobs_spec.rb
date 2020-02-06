describe Travis::Services::FindJobs do
  let(:repo)    { FactoryGirl.create(:repository) }
  let!(:job)    { FactoryGirl.create(:test, :repository => repo, :state => :created, :queue => 'builds.linux') }
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
      build = FactoryGirl.create(:build)

      Job::Test.destroy_all

      started = FactoryGirl.create(:test, :state => :started, :source => build)
      passed  = FactoryGirl.create(:test, :state => :passed,  :source => build)
      created = FactoryGirl.create(:test, :state => :created, :source => build)

      @params = { :state => ['created', 'passed'] }
      service.run.sort_by(&:id).should == [created, passed].sort_by(&:id)
    end

    it 'finds jobs that are about to run without any args' do
      build = FactoryGirl.create(:build)

      Job::Test.destroy_all

      started = FactoryGirl.create(:test, :state => :started, :source => build)
      queued = FactoryGirl.create(:test, :state => :queued, :source => build)
      passed  = FactoryGirl.create(:test, :state => :passed,  :source => build)
      created = FactoryGirl.create(:test, :state => :created, :source => build)
      received = FactoryGirl.create(:test, :state => :received, :source => build)

      @params = {}
      service.run.sort_by(&:id).should == [started, queued, created, received].sort_by(&:id)
    end
  end

  describe 'updated_at' do
    it 'returns the latest updated_at time' do
      skip 'rack cache is disabled, so not much need for caching now'

      @params = { :queue => 'builds.linux' }
      Job.delete_all
      FactoryGirl.create(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now - 1.hour)
      FactoryGirl.create(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now)
      service.updated_at.to_s.should == Time.now.to_s
    end
  end

  context do
    let(:user) { FactoryGirl.create(:user, login: :rkh) }
    let(:org)  { FactoryGirl.create(:org, login: :travis) }
    let(:private_repo) { FactoryGirl.create(:repository, owner: org, private: true) }
    let(:public_repo)  { FactoryGirl.create(:repository, owner: org, private: false) }
    let!(:private_job) { FactoryGirl.create(:job, repository: private_repo, private: true) }
    let!(:public_job)  { FactoryGirl.create(:job, repository: public_repo, private: false) }

    before { Travis.config.host = 'example.com' }

    describe 'in public mode' do
      before { Travis.config.public_mode = true }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          FactoryGirl.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          service.run.should include(private_job)
        end

        it 'finds a public job' do
          FactoryGirl.create(:permission, user: user, repository: public_repo)
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

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          FactoryGirl.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          service.run.should include(private_job)
        end

        it 'finds a public job' do
          FactoryGirl.create(:permission, user: user, repository: public_repo)
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

  context 'on .com' do
    before { Travis.config.host = "travis-ci.com" }
    after { Travis.config.host = "travis-ci.org" }

    it "doesn't return public jobs that don't belong to a user" do
      public_repo = FactoryGirl.create(:repository, :owner_name => 'foo', :name => 'bar', private: false)
      public_build = FactoryGirl.create(:build, repository: public_repo)
      FactoryGirl.create(:test, :state => :started, :source => public_build, repository: public_repo)

      user = FactoryGirl.create(:user)
      repo = FactoryGirl.create(:repository, :owner_name => 'drogus', :name => 'test-project')
      repo.users << user
      build = FactoryGirl.create(:build, repository: repo)
      job = FactoryGirl.create(:test, :state => :started, :source => build, repository: repo)

      other_user = FactoryGirl.create(:user)
      other_repo = FactoryGirl.create(:repository, private: true)
      other_repo.users << other_user
      other_build = FactoryGirl.create(:build, repository: other_repo)
      FactoryGirl.create(:test, :state => :started, :source => other_build, repository: other_repo)

      service = described_class.new(user)
      service.run.should == [job]
    end
  end
end
