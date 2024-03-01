describe Build, 'denormalization' do
  let(:build) { FactoryBot.create(:build, state: :started, duration: 30) }

  describe 'on build:started' do
    before :each do
      build.denormalize(:start)
      build.reload
    end

    it 'denormalizes last_build_id to its repository' do
      expect(build.repository.last_build_id).to eq(build.id)
    end

    it 'denormalizes last_build_state to its repository' do
      expect(build.repository.last_build_state).to eq('started')
    end

    it 'denormalizes last_build_number to its repository' do
      expect(build.repository.last_build_number).to eq(build.number)
    end

    it 'denormalizes last_build_duration to its repository' do
      expect(build.repository.last_build_duration).to eq(build.duration)
    end

    it 'denormalizes last_build_started_at to its repository' do
      expect(build.repository.last_build_started_at).to eq(build.started_at)
    end

    it 'denormalizes last_build_finished_at to its repository' do
      expect(build.repository.last_build_finished_at).to eq(build.finished_at)
    end
  end

  describe 'on build:finished' do
    before :each do
      build.update(state: :errored)
      build.denormalize(:finish)
      build.reload
    end

    it 'denormalizes last_build_state to its repository' do
      expect(build.repository.last_build_state).to eq('errored')
    end

    it 'denormalizes last_build_duration to its repository' do
      expect(build.repository.last_build_duration).to eq(build.duration)
    end

    it 'denormalizes last_build_finished_at to its repository' do
      expect(build.repository.last_build_finished_at).to eq(build.finished_at)
    end
  end
end

