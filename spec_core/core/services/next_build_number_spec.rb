require 'spec_helper'
require 'travis/services/next_build_number'

describe Travis::Services::NextBuildNumber do
  include Support::ActiveRecord

  let(:service) { described_class.new(user, params) }
  let!(:user) { Factory(:user) }
  let(:result) { service.run }
  let(:params) { { repository_id: 1234 } }
  let(:repo) do
    Factory(:repository, owner_name: 'travis-ci', name: 'travis-core')
  end

  subject { result }

  before do
    Repository.expects(:find).with(1234).returns(repo)
  end

  context 'with a new repository' do
    before(:each) { repo.next_build_number = nil }

    it 'returns 1' do
      subject.should == 1
    end

    it 'initializes the next_build_number' do
      repo.next_build_number.should be_nil
      subject
      repo.next_build_number.should == 2
    end
  end

  context 'with an existing repository' do
    let(:repo) do
      Factory(:repository,
        owner_name: 'travis-ci', name: 'travis-core', next_build_number: 4
      )
    end

    it 'returns the next_build_number' do
      subject.should == 4
    end

    it 'increments the next_build_number' do
      subject
      repo.next_build_number.should == 5
    end
  end
end
