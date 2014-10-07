require 'spec_helper'

describe Travis::Api::V2::Http::Builds do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { Travis::Api::V2::Http::Builds.new([build]).data }

  it 'builds' do
    data['builds'].first.should == {
      'id' => 1,
      'repository_id' => 1,
      'commit_id' => 1,
      'job_ids' => [1, 2],
      'number' => 2,
      'pull_request' => false,
      'pull_request_title' => nil,
      'pull_request_number' => nil,
      'config' => { 'rvm' => ['1.8.7', '1.9.2'], 'gemfile' => ['test/Gemfile.rails-2.3.x', 'test/Gemfile.rails-3.0.x'] },
      'state' => 'passed',
      'started_at' => json_format_time(Time.now.utc - 1.minute),
      'finished_at' => json_format_time(Time.now.utc),
      'duration' => 60
    }
  end

  it 'commit' do
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

  it 'uses uses cached_matrix_ids if the column exists in DB' do
    build = stub_build
    build.expects(:cached_matrix_ids).returns([1, 2, 3])
    data = Travis::Api::V2::Http::Builds.new([build]).data
    data['builds'].first['job_ids'].should == [1, 2, 3]
  end

  describe 'with a pull request' do
    let(:build) do
      stub_build pull_request?: true,
                 pull_request_title: 'A pull request',
                 pull_request_number: 44
    end

    it 'returns pull request data' do
      data['builds'].first['pull_request'].should == true
      data['builds'].first['pull_request_number'].should == 44
    end
  end
end

describe 'Travis::Api::V2::Http::Builds using Travis::Services::Builds::FindAll' do
  let!(:repo)  { Factory(:repository) }
  let(:builds) { Travis.run_service(:find_builds, nil, :event_type => 'push', :repository_id => repo.id) }
  let(:data)   { Travis::Api::V2::Http::Builds.new(builds).data }

  before :each do
    3.times { Factory(:build, :repository => repo) }
  end

  it 'queries' do
    lambda { data }.should issue_queries(3)
  end
end

