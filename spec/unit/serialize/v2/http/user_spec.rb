describe Travis::Api::Serialize::V2::Http::User do
  include Travis::Testing::Stubs, Support::Formats

  let(:user) { stub_user(repository_ids: [1, 4, 8]) }
  let(:data) { described_class.new(user).data }

  before do
    user.stubs(:github_scopes).returns(['public_repo', 'user:email'])
  end

  it 'user' do
    data['user'].should == {
      'id' => 1,
      'name' => 'Sven Fuchs',
      'login' => 'svenfuchs',
      'email' => 'svenfuchs@artweb-design.de',
      'gravatar_id' => '402602a60e500e85f2f5dc1ff3648ecb',
      'avatar_url' => 'https://0.gravatar.com/avatar/402602a60e500e85f2f5dc1ff3648ecb',
      'locale' => 'de',
      'is_syncing' => false,
      'synced_at' => json_format_time(Time.now.utc - 1.hour),
      'correct_scopes' => true,
      'created_at' => json_format_time(Time.now.utc - 2.hours),
      'channels' => ["user-1", "private-user-1"]
    }
  end
end
