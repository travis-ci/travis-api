require 'spec_helper'

describe Travis::Api::V2::Http::Requests do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) {
    Travis::Api::V2::Http::Requests.new([request]).data
  }

  it 'returns requests data' do
    data['requests'].should == [
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
        'pull_request_number' => nil
      }
    ]
  end

  it 'returns commits data' do
    data['commits'].first.should == {
      'id' => commit.id,
      'sha' => '62aae5f70ceee39123ef',
      'branch' => 'master',
      'message' => 'the commit message',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
      'committed_at' => json_format_time(Time.now.utc - 1.hour),
      'committer_email' => 'svenfuchs@artweb-design.de',
      'committer_name' => 'Sven Fuchs',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
      'pull_request_number' => nil,
    }
  end

  context "without commits" do
    let(:data) {
      request = stub_request
      request.stubs(:commit).returns(nil)
      Travis::Api::V2::Http::Requests.new([request]).data
    }

    it "doesn't fail if there is no commit data for a given request" do
      data['commits'].should == []
    end
  end
end
