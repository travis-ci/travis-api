describe Travis::Api::Serialize::V2::Http::Job do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new(test).data }

  it 'commit' do
    expect(data['commit']).to eq({
      'id' => 1,
      'sha' => '62aae5f70ceee39123ef',
      'message' => 'the commit message',
      'branch' => 'master',
      'branch_is_default' => true,
      'tag' => nil,
      'committed_at' => json_format_time(Time.now.utc - 1.hour),
      'committer_name' => 'Sven Fuchs',
      'committer_email' => 'svenfuchs@artweb-design.de',
      'author_name' => 'Sven Fuchs',
      'author_email' => 'svenfuchs@artweb-design.de',
      'compare_url' => 'https://github.com/svenfuchs/minimal/compare/master...develop',
    })
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
    let(:test) do
      stub_test(:obfuscated_config => { 'env' => 'FOO=[secure]' })
    end

    it 'shows encrypted env vars in human readable way' do
      expect(data['job']['config']['env']).to eq('FOO=[secure]')
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
end

describe Travis::Api::Serialize::V2::Http::Job, 'using Travis::Services::Jobs::FindOne' do
  let!(:record) { FactoryBot.create(:test) }
  let(:job)     { Travis.run_service(:find_job, nil, :id => record.id) }
  let(:data)    { described_class.new(job).data }

  it 'does not explode' do
    expect(data).not_to be_nil
  end
end
