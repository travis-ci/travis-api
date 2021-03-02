describe Travis::Api::Serialize::V2::Http::User do
  include Travis::Testing::Stubs, Support::Formats
  let(:user) { stub_user(repository_ids: [1, 4, 8]) }
  let(:data) { described_class.new(user).data }
  let(:expected_data) {
    {
      'id'                 => 1,
      'name'               => 'Sven Fuchs',
      'login'              => 'svenfuchs',
      'email'              => 'svenfuchs@artweb-design.de',
      'gravatar_id'        => '402602a60e500e85f2f5dc1ff3648ecb',
      'avatar_url'         => 'https://0.gravatar.com/avatar/402602a60e500e85f2f5dc1ff3648ecb',
      'locale'             => 'de',
      'is_syncing'         => false,
      'synced_at'          => json_format_time(Time.now.utc - 1.hour),
      'correct_scopes'     => true,
      'created_at'         => json_format_time(Time.now.utc - 2.hours),
      'first_logged_in_at' => json_format_time(Time.now.utc - 1.5.hours),
      'channels'           => ["private-user-1"],
      'allow_migration'    => false,
      'vcs_type'           => 'GithubUser'
    }
  }
  let!(:request) do
    WebMock.stub_request(:post, 'http://vcsfake.travis-ci.com/users/1/check_scopes')
      .to_return(
        status: 200,
        body: nil,
      )
  end
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    allow(user).to receive(:github_scopes).and_return(['public_repo', 'user:email'])
  end
  it 'user' do
    expect(data['user']).to eq(expected_data)
  end
  context 'allow_migration' do
    subject { data['user']['allow_migration'] }
    context 'when feature is not enabled for the user' do
      it { is_expected.to be_falsey }
    end
    context 'when feature is enabled for the user' do
      before { expect(Travis::Features).to receive(:user_active?).with(:allow_migration, user).and_return(true) }
      it { is_expected.to be_truthy }
    end
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
      expected_data["secure_user_hash"] = secure_user_hash
      expect(data['user']).to eq(expected_data)
    end
    after do
      Travis.config.intercom = nil
    end
  end
end
