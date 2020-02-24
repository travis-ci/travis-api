describe Travis::Services::FindJobs do
  let(:repo)    { FactoryBot.create(:repository) }
  let!(:job)    { FactoryBot.create(:test, :repository => repo, :state => :created, :queue => 'builds.linux') }
  let(:service) { described_class.new(double('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds jobs on the given queue' do
      @params = { :queue => 'builds.linux' }
      expect(service.run).to include(job)
    end

    it 'does not find jobs on other queues' do
      @params = { :queue => 'builds.nodejs' }
      expect(service.run).not_to include(job)
    end

    it 'finds jobs by a given list of ids' do
      @params = { :ids => [job.id] }
      expect(service.run).to eq([job])
    end

    it 'finds jobs by state' do
      build = FactoryBot.create(:build)

      Job::Test.destroy_all

      started = FactoryBot.create(:test, :state => :started, :source => build)
      passed  = FactoryBot.create(:test, :state => :passed,  :source => build)
      created = FactoryBot.create(:test, :state => :created, :source => build)

      @params = { :state => ['created', 'passed'] }
      expect(service.run.sort_by(&:id)).to eq([created, passed].sort_by(&:id))
    end

    it 'finds jobs that are about to run without any args' do
      build = FactoryBot.create(:build)

      Job::Test.destroy_all

      started = FactoryBot.create(:test, :state => :started, :source => build)
      queued = FactoryBot.create(:test, :state => :queued, :source => build)
      passed  = FactoryBot.create(:test, :state => :passed,  :source => build)
      created = FactoryBot.create(:test, :state => :created, :source => build)
      received = FactoryBot.create(:test, :state => :received, :source => build)

      @params = {}
      expect(service.run.sort_by(&:id)).to eq([started, queued, created, received].sort_by(&:id))
    end
  end

  describe 'updated_at' do
    it 'returns the latest updated_at time' do
      skip 'rack cache is disabled, so not much need for caching now'

      @params = { :queue => 'builds.linux' }
      Job.delete_all
      FactoryBot.create(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now - 1.hour)
      FactoryBot.create(:test, :repository => repo, :state => :queued, :queue => 'build.common', :updated_at => Time.now)
      expect(service.updated_at.to_s).to eq(Time.now.to_s)
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
          expect(service.run).to include(private_job)
        end

        it 'finds a public job' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to include(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          expect(service.run).not_to include(private_job)
        end

        it 'does not find a public job' do
          service = described_class.new(user, id: public_job.id)
          expect(service.run).not_to include(public_job)
        end
      end
    end

    describe 'in private mode' do
      before { Travis.config.public_mode = false }

      describe 'given the current user has a permission on the repository' do
        it 'finds a private job' do
          FactoryBot.create(:permission, user: user, repository: private_repo)
          service = described_class.new(user, id: private_job.id)
          expect(service.run).to include(private_job)
        end

        it 'finds a public job' do
          FactoryBot.create(:permission, user: user, repository: public_repo)
          service = described_class.new(user, id: public_job.id)
          expect(service.run).to include(public_job)
        end
      end

      describe 'given the current user does not have a permission on the repository' do
        it 'does not find a private job' do
          service = described_class.new(user, id: private_job.id)
          expect(service.run).not_to include(private_job)
        end

        it 'does not find a public job' do
          service = described_class.new(user, id: public_job.id)
          expect(service.run).not_to include(public_job)
        end
      end
    end
  end

  context 'on .com' do
    before { Travis.config.host = "travis-ci.com" }
    after { Travis.config.host = "travis-ci.org" }

    it "doesn't return public jobs that don't belong to a user" do
      public_repo = FactoryBot.create(:repository, :owner_name => 'foo', :name => 'bar', private: false)
      public_build = FactoryBot.create(:build, repository: public_repo)
      FactoryBot.create(:test, :state => :started, :source => public_build, repository: public_repo)

      user = FactoryBot.create(:user)
      repo = FactoryBot.create(:repository, :owner_name => 'drogus', :name => 'test-project')
      repo.users << user
      build = FactoryBot.create(:build, repository: repo)
      job = FactoryBot.create(:test, :state => :started, :source => build, repository: repo)

      other_user = FactoryBot.create(:user)
      other_repo = FactoryBot.create(:repository, private: true)
      other_repo.users << other_user
      other_build = FactoryBot.create(:build, repository: other_repo)
      FactoryBot.create(:test, :state => :started, :source => other_build, repository: other_repo)

      service = described_class.new(user)
      expect(service.run).to eq([job])
    end
  end
end
