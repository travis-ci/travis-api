require 'spec_helper'

class BuildMock
  include Build::States
  class << self; def name; 'Build'; end; end
  attr_accessor :state, :received_at, :started_at, :finished_at, :duration
  def denormalize(*) end
end

describe Build::States do
  include Support::ActiveRecord

  let(:build) { BuildMock.new }

  describe 'events' do
    describe 'cancel' do
      it 'cancels all the cancelable jobs' do
        build = Factory(:build)
        build.matrix.destroy_all

        created_job = Factory(:test, source: build, state: :created)
        finished_jobs = Job::Test::FINISHED_STATES.map do |state|
          Factory(:test, source: build, state: state)
        end
        build.reload

        expect {
          build.cancel!
        }.to change { created_job.reload.state }

        created_job.state.should == 'canceled'
        finished_jobs.map { |j| j.state.to_sym }.should == Job::Test::FINISHED_STATES
      end
    end

    describe 'reset' do
      before :each do
        build.stubs(:write_attribute)
      end
      it 'does not set the state to created if any jobs in the matrix are running' do
        build.stubs(matrix: [stub(state: :started)])
        build.reset
        build.state.should_not == :started
      end
      it 'sets the state to created if none of the jobs in the matrix are running' do
        build.stubs(matrix: [stub(state: :passed)])
        build.reset
        build.state.should == :created
      end
    end

    describe 'receive' do
      let(:data) { WORKER_PAYLOADS['job:test:receive'] }

      it 'does not denormalize attributes' do
        build.denormalize?('job:test:receive').should be_false
      end

      describe 'when the build is not already received' do
        it 'sets the state to :received' do
          build.receive(data)
          build.state.should == :received
        end

        it 'notifies observers' do
          Travis::Event.expects(:dispatch).with('build:received', build, data)
          build.receive(data)
        end
      end

      describe 'when the build is already received' do
        before :each do
          build.state = :received
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.receive(data)
        end
      end

      describe 'when the build has failed' do
        before :each do
          build.state = :failed
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.receive(data)
        end
      end

      describe 'when the build has errored' do
        before :each do
          build.state = :errored
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.receive(data)
        end
      end
    end

    describe 'start' do
      let(:data) { WORKER_PAYLOADS['job:test:start'] }

      describe 'when the build is not already started' do
        it 'sets the state to :started' do
          build.start(data)
          build.state.should == :started
        end

        it 'denormalizes attributes' do
          build.expects(:denormalize)
          build.start(data)
        end

        it 'notifies observers' do
          Travis::Event.expects(:dispatch).with('build:started', build, data)
          build.start(data)
        end
      end

      describe 'when the build is already started' do
        before :each do
          build.state = :started
        end

        it 'does not denormalize attributes' do
          build.expects(:denormalize).never
          build.start(data)
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.start(data)
        end
      end

      describe 'when the build has failed' do
        before :each do
          build.state = :failed
        end

        it 'does not denormalize attributes' do
          build.expects(:denormalize).never
          build.start(data)
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.start(data)
        end
      end

      describe 'when the build has errored' do
        before :each do
          build.state = :errored
        end

        it 'does not denormalize attributes' do
          build.expects(:denormalize).never
          build.start(data)
        end

        it 'does not notify observers' do
          Travis::Event.expects(:dispatch).never
          build.start(data)
        end
      end
    end

    describe 'finish' do
      let(:data) { WORKER_PAYLOADS['job:test:finish'] }

      describe 'when the matrix is not finished' do
        before(:each) do
          build.stubs(matrix_finished?: false)
        end

        describe 'when the build is already finished' do
          before(:each) do
            build.state = :finished
          end

          it 'does not denormalize attributes' do
            build.expects(:denormalize).never
            build.finish(data)
          end

          it 'does not notify observers' do
            Travis::Event.expects(:dispatch).never
            build.finish(data)
          end
        end
      end

      describe 'when the matrix is finished' do
        before(:each) do
          build.stubs(matrix_finished?: true, matrix_state: :passed, matrix_duration: 30)
        end

        describe 'when the build has not finished' do
          before(:each) do
            build.state = :started
            build.expects(:save!)
          end

          it 'sets the state to the matrix state' do
            build.finish(data)
            build.state.should == :passed
          end

          it 'calculates the duration based on the matrix durations' do
            build.finish(data)
            build.duration.should == 30
          end

          it 'denormalizes attributes' do
            build.expects(:denormalize).with(:finish, data)
            build.finish(data)
          end

          it 'notifies observers' do
            Travis::Event.expects(:dispatch).with('build:finished', build, data)
            build.finish(data)
          end
        end

        describe 'when the build has already finished' do
          before(:each) do
            build.state = :passed
          end

          it 'does not denormalize attributes' do
            build.expects(:denormalize).never
            build.finish(data)
          end

          it 'does not notify observers' do
            Travis::Event.expects(:dispatch).never
            build.finish(data)
          end
        end
      end
    end
  end
end
