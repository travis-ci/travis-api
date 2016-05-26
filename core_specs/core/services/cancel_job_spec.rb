require 'spec_helper'

describe Travis::Services::CancelJob do
  include Support::ActiveRecord

  let(:repo)    { Factory(:repository) }
  let!(:job)    { Factory(:test, repository: repo, state: :created) }
  let(:params)  { { id: job.id, source: 'tests' } }
  let(:user)    { Factory(:user) }
  let(:service) { described_class.new(user, params) }

  describe 'run' do
    it 'should cancel the job if it\'s cancelable' do
      job.stubs(:cancelable?).returns(true)
      service.stubs(:authorized?).returns(true)

      publisher = mock('publisher')
      service.stubs(:publisher).returns(publisher)
      publisher.expects(:publish).with(type: 'cancel_job', job_id: job.id, source: 'tests')

      expect {
        service.run
      }.to change { job.reload.state }

      job.state.should == 'canceled'
    end

    it 'should not cancel the job if it\'s not cancelable' do
      job.state.should == :created
      job.stubs(:cancelable?).returns(false)

      expect {
        service.run
      }.to_not change { job.state }
    end

    it 'should not be able to cancel job if user does not have pull permission' do
      user.permissions.destroy_all

      service.can_cancel?.should be_false
    end
  end
end

