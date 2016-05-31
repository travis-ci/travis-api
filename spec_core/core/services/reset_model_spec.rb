require 'spec_helper'

describe Travis::Services::ResetModel do
  include Support::ActiveRecord

  let(:user) { User.first || Factory(:user) }

  before :each do
    Travis.config.roles = {}
  end

  describe 'given a job_id' do
    let(:service) { described_class.new(user, job_id: job.id, token: 'token') }
    let(:job)     { Factory(:test, state: :passed) }

    before :each do
      service.stubs(:service).with(:find_job, id: job.id).returns(stub(run: job))
    end

    it 'resets the job' do
      user.permissions.create!(repository_id: job.repository_id, pull: true)
      job.expects(:reset!)
      service.run
    end

    it 'has message: all cool' do
      user.permissions.create!(repository_id: job.repository_id, pull: true)
      service.run
      service.messages.should == [{ notice: 'The job was successfully restarted.' }]
    end

    it 'has message: missing permissions and can not be enqueued' do
      job.stubs(:resetable?).returns(false)
      service.run
      service.messages.should == [
        { error: 'You do not seem to have sufficient permissions.' },
        { error: 'This job currently can not be restarted.' }
      ]
    end
  end

  describe 'given a build_id' do
    let(:service) { described_class.new(user, build_id: build.id, token: 'token') }
    let(:build)   { Factory(:build, state: 'passed') }

    before :each do
      service.stubs(:service).with(:find_build, id: build.id).returns(stub(run: build))
    end

    it 'resets the build (given no roles configuration and the user has permissions)' do
      user.permissions.create!(repository_id: build.repository_id, pull: true)
      build.expects(:reset!)
      service.run
    end

    it 'resets the build (given roles configuration and the user has permissions)' do
      Travis.config.roles.reset_model = 'push'
      user.permissions.create!(repository_id: build.repository_id, push: true)
      build.expects(:reset!)
      service.run
    end

    it 'does not reset the build (given no roles configuration and the user does not have permissions)' do
      build.expects(:reset!).never
      service.run
    end

    it 'does not reset the build (given roles configuration and the user does not have permissions)' do
      Travis.config.roles.reset_model = 'push'
      build.expects(:reset!).never
      service.run
    end

    describe 'Instrument' do
      let(:publisher) { Travis::Notification::Publisher::Memory.new }
      let(:event)     { publisher.events.last }

      before :each do
        Travis::Notification.publishers.replace([publisher])
      end

      it 'publishes a event' do
        service.run
        event.should publish_instrumentation_event(
          event: 'travis.services.reset_model.run:completed',
          message: "Travis::Services::ResetModel#run:completed build_id=#{build.id} not accepted",
          data: {
            type: :build,
            id: build.id,
            accept?: false
          }
        )
      end
    end
  end
end
