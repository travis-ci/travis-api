describe Travis::Api::Serialize::V2::Http::Requests do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) {
    request = stub_request
    allow(request).to receive(:build_id).and_return(1)
    allow(request).to receive(:tag_name).and_return(nil)
    described_class.new([request]).data
  }

  it 'returns requests data' do
    expect(data['requests']).to eq([
      {
        'id' => 1,
        'repository_id' => 1,
        'commit_id' => 1,
        'created_at' => '2013-01-01T00:00:00Z',
        'owner_id' => 1,
        'owner_type' => 'User',
        'event_type' => 'push',
        'base_commit' => 'base-commit',
        'head_commit' => 'head-commit',
        'result' => :accepted,
        'message' => 'a message',
        'branch' => 'master',
        'tag' => nil,
        'pull_request' => false,
        'pull_request_title' => nil,
        'pull_request_number' => nil,
        'build_id' => 1
      }
    ])
  end

  it 'returns commits data' do
    expect(data['commits'].first).to eq({
      'id' => commit.id,
      'sha' => '62aae5f70ceee39123ef',
      'branch' => 'master',
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

  context "without commits" do
    let(:data) {
      request = stub_request
      allow(request).to receive(:commit).and_return(nil)
      allow(request).to receive(:build_id).and_return(1)
      described_class.new([request]).data
    }

    it "doesn't fail if there is no commit data for a given request" do
      expect(data['commits']).to eq([])
    end
  end
end
