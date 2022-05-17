describe Travis::Api::Serialize::V2::Http::Builds do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new([build]).data }

  it 'builds' do
    expect(data['builds'].first).to eq({
      'id' => 1,
      'repository_id' => 1,
      'commit_id' => 1,
      'job_ids' => [1, 2],
      'number' => 2,
      'pull_request' => false,
      'pull_request_title' => nil,
      'pull_request_number' => nil,
      'event_type' => 'push',
      'config' => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
      'state' => 'passed',
      'started_at' => json_format_time(Time.now.utc - 1.minute),
      'finished_at' => json_format_time(Time.now.utc),
      'duration' => 60
    })
  end

  it 'commit' do
    expect(data['commits'].first).to eq({
      'id' => commit.id,
      'sha' => '62aae5f70ceee39123ef',
      'branch' => 'master',
      'tag' => nil,
      'message' => 'the commit message',
      'committed_at' => json_format_time(Time.now.utc - 1.hour),
      'committer_email' => 'svenfuchs@artweb-design.de',
      'committer_name' => 'Sven Fuchs',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
      'pull_request_number' => nil,
    })
  end

  it 'uses uses cached_matrix_ids if the column exists in DB' do
    build = stub_build
    allow(build).to receive(:cached_matrix_ids).and_return([1, 2, 3])
    data = described_class.new([build]).data
    expect(data['builds'].first['job_ids']).to eq([1, 2, 3])
  end

  describe 'with a tag' do
    before do
      allow(build.commit).to receive(:tag_name).and_return('v1.0.0')
    end

    it 'includes the tag name to commit' do
      expect(data['commits'][0]['tag']).to eq('v1.0.0')
    end
  end

  describe 'with a pull request' do
    let(:build) do
      stub_build pull_request?: true,
                 pull_request_title: 'A pull request',
                 pull_request_number: 44
    end

    it 'returns pull request data' do
      expect(data['builds'].first['pull_request']).to eq(true)
      expect(data['builds'].first['pull_request_number']).to eq(44)
    end
  end
end

describe Travis::Api::Serialize::V2::Http::Builds, 'using Travis::Services::Builds::FindAll' do
  let!(:repo)  { FactoryBot.create(:repository_without_last_build) }
  let(:builds) { Travis.run_service(:find_builds, nil, :event_type => 'push', :repository_id => repo.id) }
  let(:data)   { described_class.new(builds).data }

  before :each do
    3.times { FactoryBot.create(:build, :repository => repo) }
  end

  # checking actual data not how ActiveRecord behaves underneath :| It can be changed on every version

  it 'builds field' do
    expect(data['builds'].size).to eq(3)
  end

  it 'commits field' do
    expect(data['commits'].size).to eq(3)
  end
end
