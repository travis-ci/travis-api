describe Travis::Api::App::Endpoint::Accounts, set_app: true do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

  before do
    User.stubs(:find_by_github_id).returns(user)
    User.stubs(:find).returns(user)
    Travis::Services::FindUserAccounts.any_instance.stubs(:owners_with_counts).returns([{ 'owner_id' => user.id, 'owner_type' => 'User', 'repos_count' => 1}])
    user.stubs(:attributes).returns(:id => user.id, :login => user.login, :name => user.name)

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
