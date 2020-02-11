require 'travis/services/next_build_number'

describe Travis::Services::NextBuildNumber do
  let(:service) { described_class.new(user, params) }
  let!(:user) { FactoryBot.create(:user) }
  let(:result) { service.run }
  let(:params) { { repository_id: 1234 } }
  let(:repo) do
    FactoryBot.create(:repository_without_last_build, owner_name: 'travis-ci', name: 'travis-core')
  end

  subject { result }

  before do
    expect(Repository).to receive(:find).with(1234).and_return(repo)
  end

  context 'with a new repository' do
    before(:each) { repo.next_build_number = nil }

    it 'returns 1' do
      expect(subject).to eq(1)
    end

    it 'initializes the next_build_number' do
      expect(repo.next_build_number).to be_nil
      subject
      expect(repo.next_build_number).to eq(2)
    end
  end

  context 'with an existing repository' do
    let(:repo) do
      FactoryBot.create(:repository_without_last_build,
        owner_name: 'travis-ci', name: 'travis-core', next_build_number: 4
      )
    end

    it 'returns the next_build_number' do
      expect(subject).to eq(4)
    end

    it 'increments the next_build_number' do
      subject
      expect(repo.next_build_number).to eq(5)
    end
  end
end
