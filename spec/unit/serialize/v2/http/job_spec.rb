describe Travis::Api::Serialize::V2::Http::Job do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new(test).data }

  it 'commit' do
    data['commit'].should == {
      'id' => 1,
      'sha' => '62aae5f70ceee39123ef',
      'message' => 'the commit message',
      'branch' => 'master',
      'branch_is_default' => true,
      'committed_at' => json_format_time(Time.now.utc - 1.hour),
      'committer_name' => 'Sven Fuchs',
      'committer_email' => 'svenfuchs@artweb-design.de',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
    }
  end

  it 'annotations' do
    data['annotations'].should eq([{
      'id' => 1,
      'job_id' => 1,
      'description' => 'The job passed.',
      'url' => 'https://travis-ci.org/travis-ci/travis-ci/12345',
      'provider_name' => 'Travis CI',
      'status' => '',
    }])
  end

  context 'with encrypted env vars' do
    let(:test) do
      stub_test(:obfuscated_config => { 'env' => 'FOO=[secure]' })
    end

    it 'shows encrypted env vars in human readable way' do
      data['job']['config']['env'].should == 'FOO=[secure]'
    end
  end
end

describe Travis::Api::Serialize::V2::Http::Job, 'using Travis::Services::Jobs::FindOne' do
  let!(:record) { Factory(:test) }
  let(:job)     { Travis.run_service(:find_job, nil, :id => record.id) }
  let(:data)    { described_class.new(job).data }

  it 'does not explode' do
    data.should_not be_nil
  end
end
