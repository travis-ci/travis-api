require 'spec_helper'

describe Travis::Services::UpdateJob do
  include Support::ActiveRecord

  let(:service) { described_class.new(event: event, data: payload) }
  let(:payload) { WORKER_PAYLOADS["job:test:#{event}"].merge('id' => job.id) }
  let(:build)   { Factory(:build, state: :created, started_at: nil, finished_at: nil) }
  let(:job)     { Factory(:test, source: build, state: :started, started_at: nil, finished_at: nil) }

  before :each do
    build.matrix.delete_all
  end

  describe '#cancel_job_in_worker' do
    let(:event) { :start }

    it 'sends cancel event to the worker' do
      publisher = mock('publisher')
      service.stubs(:publisher).returns(publisher)

      publisher.expects(:publish).with(type: 'cancel_job', job_id: job.id, source: 'update_job_service')

      service.cancel_job_in_worker
    end
  end

  describe 'event: receive' do
    let(:event) { :receive }

    before :each do
      job.repository.update_attributes(last_build_state: :passed)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        service.expects(:cancel_job_in_worker)

        service.run
        job.reload.state.should == 'canceled'
      end
    end

    it 'sets the job state to received' do
      service.run
      job.reload.state.should == 'received'
    end

    it 'sets the job received_at' do
      service.run
      job.reload.received_at.to_s.should == '2011-01-01 00:02:00 UTC'
    end

    it 'sets the job worker name' do
      service.run
      job.reload.worker.should == 'ruby3.worker.travis-ci.org:travis-ruby-4'
    end

    it 'sets the build state to received' do
      service.run
      job.reload.source.state.should == 'received'
    end

    it 'sets the build received_at' do
      service.run
      job.reload.source.received_at.to_s.should == '2011-01-01 00:02:00 UTC'
    end

    it 'sets the build state to received' do
      service.run
      job.reload.source.state.should == 'received'
    end
  end


  describe 'event: start' do
    let(:event) { :start }

    before :each do
      job.repository.update_attributes(last_build_state: :passed)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        service.expects(:cancel_job_in_worker)

        service.run
        job.reload.state.should == 'canceled'
      end
    end

    it 'sets the job state to started' do
      service.run
      job.reload.state.should == 'started'
    end

    it 'sets the job started_at' do
      service.run
      job.reload.started_at.to_s.should == '2011-01-01 00:02:00 UTC'
    end

    it 'sets the build state to started' do
      service.run
      job.reload.source.state.should == 'started'
    end

    it 'sets the build started_at' do
      service.run
      job.reload.source.started_at.to_s.should == '2011-01-01 00:02:00 UTC'
    end

    it 'sets the build state to started' do
      service.run
      job.reload.source.state.should == 'started'
    end

    it 'sets the repository last_build_state to started' do
      service.run
      job.reload.repository.last_build_state.should == 'started'
    end

    it 'sets the repository last_build_started_at' do
      service.run
      job.reload.repository.last_build_started_at.to_s.should == '2011-01-01 00:02:00 UTC'
    end
  end

  describe 'event: finish' do
    let(:event) { :finish }

    before :each do
      job.repository.update_attributes(last_build_state: :started)
    end

    context 'when job is canceled' do
      before { job.update_attribute(:state, :canceled) }

      it 'does not update state' do
        service.expects(:cancel_job_in_worker)

        service.run
        job.reload.state.should == 'canceled'
      end
    end

    it 'sets the job state to passed' do
      service.run
      job.reload.state.should == 'passed'
    end

    it 'sets the job finished_at' do
      service.run
      job.reload.finished_at.to_s.should == '2011-01-01 00:03:00 UTC'
    end

    it 'sets the build state to passed' do
      service.run
      job.reload.source.state.should == 'passed'
    end

    it 'sets the build finished_at' do
      service.run
      job.reload.source.finished_at.to_s.should == '2011-01-01 00:03:00 UTC'
    end

    it 'sets the repository last_build_state to passed' do
      service.run
      job.reload.repository.last_build_state.should == 'passed'
    end

    it 'sets the repository last_build_finished_at' do
      service.run
      job.reload.repository.last_build_finished_at.to_s.should == '2011-01-01 00:03:00 UTC'
    end
  end

  describe 'compat' do
    let(:event) { :finish }

    it 'swaps :result for :state (passed) if present' do
      payload.delete(:state)
      payload.merge!(result: 0)
      service.data[:state].should == :passed
    end

    it 'swaps :result for :state (failed) if present' do
      payload.delete(:state)
      payload.merge!(result: 1)
      service.data[:state].should == :failed
    end
  end

  describe 'event: reset' do
    let(:event) { :reset }

    before :each do
      job.repository.update_attributes(last_build_state: :passed)
    end

    it 'sets the job state to created' do
      service.run
      job.reload.state.should == 'created'
    end

    it 'resets the job started_at' do
      service.run
      job.reload.started_at.should be_nil
    end

    it 'resets the job worker name' do
      service.run
      job.reload.worker.should be_nil
    end

    it 'resets the build state to started' do
      service.run
      job.reload.source.state.should == 'created'
    end

    it 'resets the build started_at' do
      service.run
      job.reload.source.started_at.should be_nil
    end

    it 'resets the build state to started' do
      service.run
      job.reload.source.state.should == 'created'
    end

    it 'resets the repository last_build_state to started' do
      service.run
      job.reload.repository.last_build_state.should == 'created'
    end

    it 'resets the repository last_build_started_at' do
      service.run
      job.reload.repository.last_build_started_at.should be_nil
    end
  end
end
