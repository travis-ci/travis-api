describe Travis::Services::UpdateJob do
  before { DatabaseCleaner.clean_with :truncation }

  let(:service) { described_class.new(event: event, data: payload) }
  let(:payload) { WORKER_PAYLOADS["job:test:#{event}"].merge('id' => job.id) }
  let(:build)   { FactoryBot.create(:build, state: :created, started_at: nil, finished_at: nil) }
  let(:job)     { FactoryBot.create(:test, source: build, state: :started, started_at: nil, finished_at: nil) }
  let(:log)     { Travis::RemoteLog.new(job_id: job.id) }

  before :each do
    build.matrix.delete_all
    remote = double('remote')
    allow(Travis::RemoteLog::Remote).to receive(:new).and_return(remote)
    allow(remote).to receive(:find_by_job_id).and_return(log)
    allow(remote).to receive(:write_content_for_job_id).and_return(log)
  end

  describe '#cancel_job_in_worker' do
    let(:event) { :start }

    it 'sends cancel event to the worker' do
      publisher = double('publisher')
      allow(service).to receive(:publisher).and_return(publisher)

      expect(publisher).to receive(:publish).with(type: 'cancel_job', job_id: job.id, source: 'update_job_service', reason: 'Some event other than reset was called on the job!')

      service.cancel_job_in_worker
    end
  end

  describe 'event: receive' do
    let(:event) { :receive }

    before :each do
      job.repository.update(last_build_state: :passed)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        expect(service).to receive(:cancel_job_in_worker)

        service.run
        expect(job.reload.state).to eq(:canceled)
      end
    end

    it 'sets the job state to received' do
      service.run
      expect(job.reload.state).to eq(:received)
    end

    it 'sets the job received_at' do
      service.run
      expect(job.reload.received_at.to_s).to eq('2011-01-01 00:02:00 UTC')
    end

    it 'sets the job worker name' do
      service.run
      expect(job.reload.worker).to eq('ruby3.worker.travis-ci.org:travis-ruby-4')
    end

    it 'sets the build state to received' do
      service.run
      expect(job.reload.source.state).to eq(:received)
    end

    it 'sets the build received_at' do
      service.run
      expect(job.reload.source.received_at.to_s).to eq('2011-01-01 00:02:00 UTC')
    end

    it 'sets the build state to received' do
      service.run
      expect(job.reload.source.state).to eq(:received)
    end
  end


  describe 'event: start' do
    let(:event) { :start }

    before :each do
      job.repository.update(last_build_state: :passed)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        expect(service).to receive(:cancel_job_in_worker)

        service.run
        expect(job.reload.state).to eq(:canceled)
      end
    end

    it 'sets the job state to started' do
      service.run
      expect(job.reload.state).to eq(:started)
    end

    it 'sets the job started_at' do
      service.run
      expect(job.reload.started_at.to_s).to eq('2011-01-01 00:02:00 UTC')
    end

    it 'sets the build state to started' do
      service.run
      expect(job.reload.source.state).to eq(:started)
    end

    it 'sets the build started_at' do
      service.run
      expect(job.reload.source.started_at.to_s).to eq('2011-01-01 00:02:00 UTC')
    end

    it 'sets the build state to started' do
      service.run
      expect(job.reload.source.state).to eq(:started)
    end

    it 'sets the repository last_build_state to started' do
      service.run
      expect(job.reload.repository.last_build_state).to eq('started')
    end

    it 'sets the repository last_build_started_at' do
      service.run
      expect(job.reload.repository.last_build_started_at.to_s).to eq('2011-01-01 00:02:00 UTC')
    end
  end

  describe 'event: finish' do
    let(:event) { :finish }

    before :each do
      job.repository.update(last_build_state: :started)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        expect(service).to receive(:cancel_job_in_worker)

        service.run
        expect(job.reload.state).to eq(:canceled)
      end
    end

    it 'sets the job state to passed' do
      service.run
      expect(job.reload.state).to eq(:passed)
    end

    it 'sets the job finished_at' do
      service.run
      expect(job.reload.finished_at.to_s).to eq('2011-01-01 00:03:00 UTC')
    end

    it 'sets the build state to passed' do
      service.run
      expect(job.reload.source.state).to eq(:passed)
    end

    it 'sets the build finished_at' do
      service.run
      expect(job.reload.source.finished_at.to_s).to eq('2011-01-01 00:03:00 UTC')
    end

    it 'sets the repository last_build_state to passed' do
      service.run
      expect(job.reload.repository.last_build_state).to eq('passed')
    end

    it 'sets the repository last_build_finished_at' do
      service.run
      expect(job.reload.repository.last_build_finished_at.to_s).to eq('2011-01-01 00:03:00 UTC')
    end
  end

  describe 'compat' do
    let(:event) { :finish }

    it 'swaps :result for :state (passed) if present' do
      payload.delete(:state)
      payload.merge!(result: 0)
      expect(service.data[:state]).to eq(:passed)
    end

    it 'swaps :result for :state (failed) if present' do
      payload.delete(:state)
      payload.merge!(result: 1)
      expect(service.data[:state]).to eq(:failed)
    end
  end

  describe 'event: reset' do
    let(:event) { :reset }

    before :each do
      job.repository.update(last_build_state: :passed)
    end

    it 'sets the job state to created' do
      service.run
      expect(job.reload.state).to eq(:created)
    end

    it 'resets the job started_at' do
      service.run
      expect(job.reload.started_at).to be_nil
    end

    it 'resets the job worker name' do
      service.run
      expect(job.reload.worker).to be_nil
    end

    it 'resets the build state to started' do
      service.run
      expect(job.reload.source.state).to eq(:created)
    end

    it 'resets the build started_at' do
      service.run
      expect(job.reload.source.started_at).to be_nil
    end

    it 'resets the build state to started' do
      service.run
      expect(job.reload.source.state).to eq(:created)
    end

    it 'resets the repository last_build_state to started' do
      service.run
      expect(job.reload.repository.last_build_state).to eq('created')
    end

    it 'resets the repository last_build_started_at' do
      service.run
      expect(job.reload.repository.last_build_started_at).to be_nil
    end
  end
end
