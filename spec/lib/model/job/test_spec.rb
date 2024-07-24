describe Job::Test do
  let(:job) { FactoryBot.create(:test) }
  let(:log) { Travis::RemoteLog.new(job_id: job.id) }

  before :each do
    allow(Travis::Event).to receive(:dispatch)
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(log)
    allow(remote).to receive(:write_content_for_job_id).and_return(log)
  end

  it 'is cancelable if the job has not finished yet' do
    job = FactoryBot.create(:test, state: :created)
    expect(job).to be_cancelable

    job = FactoryBot.create(:test, state: :started)
    expect(job).to be_cancelable
  end

  it 'is not cancelable if the job has already been finished' do
    job = FactoryBot.create(:test, state: :passed)
    expect(job).not_to be_cancelable
  end

  describe 'cancelling' do
    it 'should not propagate cancel state to source' do
      build = FactoryBot.create(:build, state: :started)
      build.matrix.destroy_all
      job = FactoryBot.create(:test, state: :created, source: build)
      FactoryBot.create(:test, state: :started, source: build)
      build.reload
      expect {
        job.cancel!
      }.to_not change { job.source.reload.state }
    end

    it 'should put a build into canceled state if all the jobs in matrix are in finished state' do
      build = FactoryBot.create(:build, state: :started)
      build.matrix.destroy_all
      job = FactoryBot.create(:test, state: :created, source: build)
      Job::Test::FINISHED_STATES.each do |state|
        FactoryBot.create(:test, source: build, state: state)
      end
      build.reload

      expect {
      expect {
      expect {
        job.cancel!
      }.to change { build.state }
      }.to change { build.canceled_at }
      }.to change { build.repository.reload.last_build_state }

      expect(build.reload.state).to eq(:canceled)
      expect(build.repository.last_build_state).to eq('canceled')
    end

    it 'should set canceled_at and finished_at on job' do
      job = FactoryBot.create(:test, state: :created)

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
        expect(job.state).to eq(:received)
      end

      it 'sets the worker from the payload' do
        job.receive(data)
        expect(job.worker).to eq('ruby3.worker.travis-ci.org:travis-ruby-4')
      end

      it 'propagates the event to the source' do
        expect(job.source).to receive(:receive)
        job.receive(data)
      end
    end

    describe 'start' do
      let(:data) { WORKER_PAYLOADS['job:test:start'] }

      it 'sets the state to :started' do
        job.start(data)
        expect(job.state).to eq(:started)
      end

      it 'propagates the event to the source' do
        expect(job.source).to receive(:start)
        job.start(data)
      end
    end

    describe 'finish' do
      let(:data) { WORKER_PAYLOADS['job:test:finish'] }

      it 'sets the state to the given result state' do
        job.finish(data)
        expect(job.state).to eq(:passed)
      end

      it 'propagates the event to the source' do
        expect(job.source).to receive(:finish).with(data)
        job.finish(data)
      end
    end

    describe 'reset' do
      let(:job) { FactoryBot.create(:test, state: 'finished', queued_at: Time.now, finished_at: Time.now) }

      it 'sets the state to :created' do
        job.reset!
        expect(job.reload.state).to eq(:created)
      end

      it 'resets job attributes' do
        job.reset!
        expect(job.reload.queued_at).to be_nil
        expect(job.reload.finished_at).to be_nil
      end

      it 'resets log attributes' do
        expect(log).to receive(:clear!)
        job.reset!
      end
    end
  end
end
