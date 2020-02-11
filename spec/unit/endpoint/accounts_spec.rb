describe Travis::Api::App::Endpoint::Accounts, set_app: true do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

  before do
    allow(User).to receive(:find_by_github_id).and_return(user)
    allow(User).to receive(:find).and_return(user)
    allow_any_instance_of(Travis::Services::FindUserAccounts).to receive(:owners_with_counts).and_return([{ 'owner_id' => user.id, 'owner_type' => 'User', 'repos_count' => 1}])
    allow(user).to receive(:attributes).and_return(:id => user.id, :login => user.login, :name => user.name)

  end

  it 'includes accounts' do
    expect(get('/accounts', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01')).to be_ok
    expect(parsed_body['accounts']).to eq([{
      'id'          => user.id,
      'login'       => user.login,
      'name'        => user.name,
      'type'        => 'user',
      'repos_count' => 1,
      'avatar_url'  => nil
    }])
  end
end
