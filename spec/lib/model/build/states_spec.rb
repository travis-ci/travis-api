class BuildMock
  include Build::States
  class << self; def name; 'Build'; end; end
  attr_accessor :state, :received_at, :started_at, :finished_at, :duration
  def denormalize(*) end
end

describe Build::States do
  let(:build) { BuildMock.new }

  describe 'events' do
    describe 'cancel' do
      it 'cancels all the cancelable jobs' do
        build = FactoryBot.create(:build)
        build.matrix.destroy_all

        created_job = FactoryBot.create(:test, source: build, state: :created)
        finished_jobs = Job::Test::FINISHED_STATES.map do |state|
          FactoryBot.create(:test, source: build, state: state)
        end
        build.reload

        expect {
          build.cancel!
        }.to change { created_job.reload.state }

        expect(created_job.state).to eq(:canceled)
        expect(finished_jobs.map { |j| j.state.to_sym }).to eq(Job::Test::FINISHED_STATES)
      end
    end

    describe 'reset' do
      before :each do
        allow(build).to receive(:write_attribute)
      end
      it 'does not set the state to created if any jobs in the matrix are running' do
        allow(build).to receive(:matrix).and_return([double(state: :started)])
        build.reset
        expect(build.state).not_to eq(:started)
      end
      it 'sets the state to created if none of the jobs in the matrix are running' do
        allow(build).to receive(:matrix).and_return([double(state: :passed)])
        build.reset
        expect(build.state).to eq(:created)
      end
    end

    describe 'receive' do
      let(:data) { WORKER_PAYLOADS['job:test:receive'] }

      it 'does not denormalize attributes' do
        expect(build.denormalize?('job:test:receive')).to be false
      end

      describe 'when the build is not already received' do
        it 'sets the state to :received' do
          build.receive(data)
          expect(build.state).to eq(:received)
        end
      end

      describe 'when the build is already received' do
        before :each do
          build.state = :received
        end
      end

      describe 'when the build has failed' do
        before :each do
          build.state = :failed
        end
      end

      describe 'when the build has errored' do
        before :each do
          build.state = :errored
        end
      end
    end

    describe 'start' do
      let(:data) { WORKER_PAYLOADS['job:test:start'] }

      describe 'when the build is not already started' do
        it 'sets the state to :started' do
          build.start(data)
          expect(build.state).to eq(:started)
        end

        it 'denormalizes attributes' do
          expect(build).to receive(:denormalize)
          build.start(data)
        end
      end

      describe 'when the build is already started' do
        before :each do
          build.state = :started
        end

        it 'does not denormalize attributes' do
          expect(build).not_to receive(:denormalize)
          build.start(data)
        end
      end

      describe 'when the build has failed' do
        before :each do
          build.state = :failed
        end

        it 'does not denormalize attributes' do
          expect(build).not_to receive(:denormalize)
          build.start(data)
        end
      end

      describe 'when the build has errored' do
        before :each do
          build.state = :errored
        end

        it 'does not denormalize attributes' do
          expect(build).not_to receive(:denormalize)
          build.start(data)
        end
      end
    end

    describe 'finish' do
      let(:data) { WORKER_PAYLOADS['job:test:finish'] }

      describe 'when the matrix is not finished' do
        before(:each) do
          allow(build).to receive(:matrix_finished?).and_return(false)
        end

        describe 'when the build is already finished' do
          before(:each) do
            build.state = :finished
          end

          it 'does not denormalize attributes' do
            expect(build).not_to receive(:denormalize)
            build.finish(data)
          end
        end
      end

      describe 'when the matrix is finished' do
        before(:each) do
          allow(build).to receive(:matrix_finished?).and_return(true)
          allow(build).to receive(:matrix_state).and_return(:passed)
          allow(build).to receive(:matrix_duration).and_return(30)
        end

        describe 'when the build has not finished' do
          before(:each) do
            build.state = :started
            expect(build).to receive(:save!)
          end

          it 'sets the state to the matrix state' do
            build.finish(data)
            expect(build.state).to eq(:passed)
          end

          it 'calculates the duration based on the matrix durations' do
            build.finish(data)
            expect(build.duration).to eq(30)
          end

          it 'denormalizes attributes' do
            expect(build).to receive(:denormalize).with(:finish, data)
            build.finish(data)
          end
        end

        describe 'when the build has already finished' do
          before(:each) do
            build.state = :passed
          end

          it 'does not denormalize attributes' do
            expect(build).not_to receive(:denormalize)
            build.finish(data)
          end
        end
      end
    end
  end
end
