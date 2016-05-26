require 'spec_helper'

describe Travis::Services::FindLog do
  include Support::ActiveRecord

  let!(:job)    { Factory(:test) }
  let(:log)     { job.log }
  let(:service) { described_class.new(stub('user'), params) }

  attr_reader :params

  describe 'run' do
    it 'finds the log with the given id' do
      @params = { id: log.id }
      service.run.should == log
    end

    it 'finds the log with the given job_id' do
      @params = { job_id: job.id }
      service.run.should == log
    end

    it 'does not raise if the log could not be found' do
      @params = { id: log.id + 1 }
      lambda { service.run }.should_not raise_error
    end
  end

  # TODO jobs can be requeued, so finished jobs are no more final
  #
  # describe 'final?' do
  #   it 'returns true if the job is finished' do
  #     log.job.update_attributes!(:state => :finished)
  #     service.final?.should be_true
  #   end

  #   it 'returns false if the job is not finished' do
  #     log.job.update_attributes!(:state => :started)
  #     service.final?.should be_false
  #   end
  # end
end
