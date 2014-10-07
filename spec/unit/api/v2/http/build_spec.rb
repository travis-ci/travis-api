require 'spec_helper'

describe Travis::Api::V2::Http::Build do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { Travis::Api::V2::Http::Build.new(build).data }

  it 'build' do
    data['build'].should == {
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
    data['commit'].should == {
      'id' => 1,
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
    }
  end

  describe 'pull request' do
    let(:build) do
      stub_build pull_request?: true,
                 pull_request_title: 'A pull request',
                 pull_request_number: 44
    end
    let(:data) { Travis::Api::V2::Http::Build.new(build).data }

    it 'returns pull request data' do
      data['build']['pull_request'].should == true
      data['build']['pull_request_title'].should == 'A pull request'
      data['build']['pull_request_number'].should == 44
    end

  end

  context 'with encrypted env vars' do
    let(:build) do
      stub_build(:obfuscated_config => { 'env' => 'FOO=[secure]' })
    end

    it 'shows encrypted env vars in human readable way' do
      data['build']['config']['env'].should == 'FOO=[secure]'
    end
  end

  context 'without logs' do
    before { build.matrix.first.stubs(:log).returns(nil) }

    it 'returns null log_id' do
      data['log_id'].should be_nil
    end
  end
end

describe 'Travis::Api::V2::Http::Build using Travis::Services::Builds::FindOne' do
  let!(:record) { Factory(:build) }
  let(:build)   { Travis.run_service(:find_build, nil, :id => record.id) }
  let(:data)    { Travis::Api::V2::Http::Build.new(build).data }

  it 'queries' do
    lambda { data }.should issue_queries(6)
  end
end

