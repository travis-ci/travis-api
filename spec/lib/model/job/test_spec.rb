describe Job::Test do
  let(:job) { Factory(:test) }
  let(:log) { Travis::RemoteLog.new(job_id: job.id) }

  before :each do
    Travis::Event.stubs(:dispatch)
    Travis::RemoteLog.stubs(:find_by_job_id).returns(log)
    Travis::RemoteLog.stubs(:write_content_for_job_id).returns(log)
  end

  it 'is cancelable if the job has not finished yet' do
    job = Factory(:test, state: :created)
    job.should be_cancelable

    job = Factory(:test, state: :started)
    job.should be_cancelable
  end

  it 'is not cancelable if the job has already been finished' do
    job = Factory(:test, state: :passed)
    job.should_not be_cancelable
  end

  describe 'cancelling' do
    it 'should not propagate cancel state to source' do
      build = Factory(:build, state: :started)
      build.matrix.destroy_all
      job = Factory(:test, state: :created, source: build)
      Factory(:test, state: :started, source: build)
      build.reload

      expect {
        job.cancel!
      }.to_not change { job.source.reload.state }
    end

    it 'should put a build into canceled state if all the jobs in matrix are in finished state' do
      build = Factory(:build, state: :started)
      build.matrix.destroy_all
      job = Factory(:test, state: :created, source: build)
      Job::Test::FINISHED_STATES.each do |state|
        Factory(:test, source: build, state: state)
      end
      build.reload

      expect {
      expect {
      expect {
        job.cancel!
      }.to change { build.state }
      }.to change { build.canceled_at }
      }.to change { build.repository.reload.last_build_state }

      build.reload.state.should == :canceled
      build.repository.last_build_state.should == 'canceled'
    end

    it 'should set canceled_at and finished_at on job' do
      job = Factory(:test, state: :created)

      expect {
      expect {
        job.cancel!
      }.to change { job.canceled_at }
      }.to change { job.finished_at }
    end
  end

  describe 'events' do
    describe 'receive' do
      let(:data) { WORKER_PAYLOADS['job:test:receive'] }

      it 'sets the state to :received' do
        job.receive(data)
        job.state.should == :received
      end

      it 'sets the worker from the payload' do
        job.receive(data)
        job.worker.should == 'ruby3.worker.travis-ci.org:travis-ruby-4'
      end

      it 'propagates the event to the source' do
        job.source.expects(:receive)
        job.receive(data)
      end
    end

    describe 'start' do
      let(:data) { WORKER_PAYLOADS['job:test:start'] }

      it 'sets the state to :started' do
        job.start(data)
        job.state.should == :started
      end

      it 'propagates the event to the source' do
        job.source.expects(:start)
        job.start(data)
      end
    end

    describe 'finish' do
      let(:data) { WORKER_PAYLOADS['job:test:finish'] }

      it 'sets the state to the given result state' do
        job.finish(data)
        job.state.should == :passed
      end

      it 'propagates the event to the source' do
        job.source.expects(:finish).with(data)
        job.finish(data)
      end
    end

    describe 'reset' do
      let(:job) { Factory(:test, state: 'finished', queued_at: Time.now, finished_at: Time.now) }

      it 'sets the state to :created' do
        job.reset!
        job.reload.state.should == :created
      end

      it 'resets job attributes' do
        job.reset!
        job.reload.queued_at.should be_nil
        job.reload.finished_at.should be_nil
      end

      it 'resets log attributes' do
        log.expects(:clear!)
        job.reset!
      end
    end
  end
end
