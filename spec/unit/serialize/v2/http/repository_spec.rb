describe Travis::Api::Serialize::V2::Http::Repository do
  include Travis::Testing::Stubs
  include Support::Formats

  let(:data) { described_class.new(repository).data }

  it 'repository' do
    expect(data['repo']).to eq({
      'id' => repository.id,
      'slug' => 'svenfuchs/minimal',
      'description' => 'the repo description',
      'active' => true,
      'last_build_id' => 1,
      'last_build_number' => 2,
      'last_build_started_at' => json_format_time(Time.now.utc - 1.minute),
      'last_build_finished_at' => json_format_time(Time.now.utc),
      'last_build_state' => 'passed',
      'last_build_language' => nil,
      'last_build_duration' => 60,
      'github_language' => 'ruby'
    })
  end
end

describe Travis::Api::Serialize::V2::Http::Repository, 'using Travis::Services::FindRepo' do
  let!(:record) { FactoryBot.create(:repository) }
  let(:repo)    { Travis.run_service(:find_repo, :id => record.id) }
  let(:data)    { described_class.new(repo).data }

  it 'queries' do
    expect { data }.to issue_queries(1)
  end
end
