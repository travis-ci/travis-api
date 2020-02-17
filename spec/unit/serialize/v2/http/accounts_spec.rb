describe Travis::Api::Serialize::V2::Http::Accounts do
  include Travis::Testing::Stubs, Support::Formats

  let(:user)     { { 'id' => 1, 'type' => 'User', 'login' => 'sven', 'name' => 'Sven', 'repos_count' => 2 } }
  let(:org)      { { 'id' => 1, 'type' => 'Organization', 'login' => 'travis', 'name' => 'Travis', 'repos_count' => 1, 'avatar_url' => 'https://example.org/avatar.png' } }

  let(:accounts) { [Account.new(user), Account.new(org)] }
  let(:data)     { described_class.new(accounts).data }

  it 'accounts' do
    expect(data[:accounts]).to eq([
      { 'id' => 1, 'login' => 'sven', 'name' => 'Sven', 'type' => 'user', 'repos_count' => 2, 'avatar_url' => nil },
      { 'id' => 1, 'login' => 'travis', 'name' => 'Travis', 'type' => 'organization', 'repos_count' => 1, 'avatar_url' => 'https://example.org/avatar.png' }
    ])
  end
end

