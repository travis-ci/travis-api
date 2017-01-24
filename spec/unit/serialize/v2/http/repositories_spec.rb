describe Travis::Api::Serialize::V2::Http::Repositories do
  include Travis::Testing::Stubs, Support::Formats

  let(:data) { described_class.new([repository]).data }

  it 'repositories' do
    data['repos'].first.should == {
      'id' => repository.id,
      'slug' => 'svenfuchs/minimal',
      'description' => 'the repo description',
      'last_build_id' => 1,
      'last_build_number' => 2,
      'last_build_started_at' => json_format_time(Time.now.utc - 1.minute),
      'last_build_finished_at' => json_format_time(Time.now.utc),
      'last_build_state' => 'passed',
      'last_build_language' => nil,
      'last_build_duration' => 60,
      'enabled' => true,
      'github_language' => 'ruby'
    }
  end
end

describe Travis::Api::Serialize::V2::Http::Repositories, 'using Travis::Services::FindRepos' do
  let(:user)  { Factory(:user) }
  let(:repo)  { Factory(:repository, :owner_name => 'travis-ci', :name => 'travis-core', :enabled => true) }
  let(:repos) { Travis::Services::FindRepos.new(user, {ids: [repo.id]}).run }
  let(:data)  { described_class.new(repos).data }

  it 'queries' do
    user.permissions.create!(admin: true, push: true, repository_id: repo.id)
    lambda { data }.should issue_queries(1)
  end
end
