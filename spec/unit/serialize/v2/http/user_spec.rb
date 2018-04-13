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
      'first_logged_in_at' => json_format_time(Time.now.utc - 4.hours),
      'channels' => ["private-user-1"]
    }
  end

  context 'when there is an Intercom HMAC secret key' do
    before do
      Travis.config.intercom = {
        hmac_secret_key: 'USER_HASH_SECRET_KEY'
      }
    end

    it 'user' do
      secure_user_hash = OpenSSL::HMAC.hexdigest(
        'sha256',
        'USER_HASH_SECRET_KEY',
        '1'
      )

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
        'first_logged_in_at' => json_format_time(Time.now.utc - 4.hours),
        'secure_user_hash' => secure_user_hash,
        'channels' => ["private-user-1"]
      }
    end

    after do
      Travis.config.intercom = nil
    end
  end
end
