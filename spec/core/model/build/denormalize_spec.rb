require 'spec_helper'

describe Build, 'denormalization' do
  include Support::ActiveRecord

  let(:build) { Factory(:build, state: :started, duration: 30) }

  describe 'on build:started' do
    before :each do
      build.denormalize(:start)
      build.reload
    end

    it 'denormalizes last_build_id to its repository' do
      build.repository.last_build_id.should == build.id
    end

    it 'denormalizes last_build_state to its repository' do
      build.repository.last_build_state.should == 'started'
    end

    it 'denormalizes last_build_number to its repository' do
      build.repository.last_build_number.should == build.number
    end

    it 'denormalizes last_build_duration to its repository' do
      build.repository.last_build_duration.should == build.duration
    end

    it 'denormalizes last_build_started_at to its repository' do
      build.repository.last_build_started_at.should == build.started_at
    end

    it 'denormalizes last_build_finished_at to its repository' do
      build.repository.last_build_finished_at.should == build.finished_at
    end
  end

  describe 'on build:finished' do
    before :each do
      build.update_attributes(state: :errored)
      build.denormalize(:finish)
      build.reload
    end

    it 'denormalizes last_build_state to its repository' do
      build.repository.last_build_state.should == 'errored'
    end

    it 'denormalizes last_build_duration to its repository' do
      build.repository.last_build_duration.should == build.duration
    end

    it 'denormalizes last_build_finished_at to its repository' do
      build.repository.last_build_finished_at.should == build.finished_at
    end
  end
end

