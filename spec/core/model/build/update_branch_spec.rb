require 'spec_helper'

describe Build::UpdateBranch do
  include Support::ActiveRecord

  let(:request) { Factory.create(:request, event_type: event_type) }
  let(:build)   { Factory.build(:build, request: request, state: :started, duration: 30, branch: 'master') }
  let(:branch)  { Branch.where(repository_id: build.repository_id, name: build.branch).first }

  subject { described_class.new(build) }

  shared_examples_for 'updates the branch' do
    describe 'creates branch if missing' do
      before { build.save! }
      it { branch.should_not be_nil }
      it { branch.last_build_id.should be == build.id }
    end

    describe 'updates an existing branch' do
      before { Branch.create!(repository_id: build.repository_id, name: 'master', last_build_id: 0) }
      before { build.save! }
      it { branch.should_not be_nil }
      it { branch.last_build_id.should be == build.id }
    end
  end

  shared_examples_for 'does not update the branch' do
    describe 'does not create a branch' do
      before { build.save! }
      it { branch.should be_nil }
    end

    describe 'does update existing branchs' do
      before { Branch.create!(repository_id: build.repository_id, name: 'master', last_build_id: 0) }
      before { build.save! }
      it { branch.should_not be_nil }
      it { branch.last_build_id.should be == 0 }
    end
  end

  describe 'on build creation' do
    describe 'for push events' do
      let(:event_type) { 'push' }
      include_examples 'updates the branch'
    end

    describe 'for api events' do
      let(:event_type) { 'api' }
      include_examples 'updates the branch'
    end

    describe 'for pull request events' do
      let(:event_type) { 'pull_request' }
      include_examples 'does not update the branch'
    end
  end
end
