describe Travis::Api::Serialize::V2::Http::Jobs do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new([test]).data }
  let!(:time) { Time.now.utc }

  it 'commits' do
    data['commits'].first.should == {
      'id' => 1,
      'sha' => '62aae5f70ceee39123ef',
      'branch' => 'master',
      'tag' => nil,
      'message' => 'the commit message',
      'committed_at' => json_format_time(time - 1.hour),
      'committer_name' => 'Sven Fuchs',
      'committer_email' => 'svenfuchs@artweb-design.de',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
    }
  end

  describe 'with a tag' do
    before do
      test.commit.stubs(tag_name: 'v1.0.0')
    end

    it 'includes the tag name to commit' do
      data['commits'][0]['tag'].should == 'v1.0.0'
    end
  end
end

describe Travis::Api::Serialize::V2::Http::Jobs, 'using Travis::Services::Jobs::FindAll' do
  let(:jobs) { Travis.run_service(:find_jobs, nil) }
  let(:data) { described_class.new(jobs).data }

  before :each do
    3.times { Factory(:test) }
  end

  it 'does not explode' do
    data.should_not be_nil
  end
end
