describe Travis::Api::Serialize::V2::Http::Build do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new(build).data }

  it 'build' do
    expect(data['build']).to eq({
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
    expect(data['commit']).to eq({
      'id' => 1,
      'sha' => '62aae5f70ceee39123ef',
      'branch' => 'master',
      'branch_is_default' => true,
      'tag' => nil,
      'message' => 'the commit message',
      'committed_at' => json_format_time(Time.now.utc - 1.hour),
      'committer_email' => 'svenfuchs@artweb-design.de',
      'committer_name' => 'Sven Fuchs',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
    })
  end

  describe 'pull request' do
    let(:build) do
      stub_build pull_request?: true,
                 pull_request_title: 'A pull request',
                 pull_request_number: 44
    end
    let(:data) { described_class.new(build).data }

    it 'returns pull request data' do
      expect(data['build']['pull_request']).to eq(true)
      expect(data['build']['pull_request_title']).to eq('A pull request')
      expect(data['build']['pull_request_number']).to eq(44)
    end
  end

  describe 'with a tag' do
    before do
      allow(test.commit).to receive(:tag_name).and_return('v1.0.0')
    end

    it 'includes the tag name to commit' do
      expect(data['commit']['tag']).to eq('v1.0.0')
    end
  end

  describe 'with a tag' do
    before do
      allow(test.commit).to receive(:tag_name).and_return('v1.0.0')
    end

    it 'includes the tag name to commit' do
      expect(data['commit']['tag']).to eq('v1.0.0')
    end
  end

  context 'with encrypted env vars' do
    let(:build) do
      stub_build(:obfuscated_config => { 'env' => 'FOO=[secure]' })
    end

    it 'shows encrypted env vars in human readable way' do
      expect(data['build']['config']['env']).to eq('FOO=[secure]')
    end
  end

  context 'without logs' do
    before { allow(build.matrix.first).to receive(:log).and_return(nil) }

    it 'returns null log_id' do
      expect(data['log_id']).to be_nil
    end
  end
end

describe Travis::Api::Serialize::V2::Http::Build, 'using Travis::Services::Builds::FindOne' do
  let!(:record) { FactoryBot.create(:build) }
  let(:build)   { Travis.run_service(:find_build, nil, :id => record.id) }
  let(:data)    { described_class.new(build).data }

  it 'does not explode' do
    expect(data).not_to be_nil
  end
end
