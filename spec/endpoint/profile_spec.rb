require 'spec_helper'

describe Travis::Api::App::Endpoint::Profile do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

  before do
    User.stubs(:find_by_github_id).returns(user)
    User.stubs(:find).returns(user)
    user.stubs(:repositories).returns(stub(administratable: stub(select: [repository])))
  end

  it 'needs to be authenticated' do
    get('/profile').should_not be_ok
  end

  it 'replies with the current user' do
    get('/profile', access_token: access_token.to_s).should be_ok
    parsed_body['user'].should == {
      'id'          => user.id,
      'login'       => user.login,
      'name'        => user.name,
      'email'       => user.email,
      'gravatar_id' => user.gravatar_id,
      'locale'      => user.locale,
      'is_syncing'  => user.is_syncing,
      'synced_at'   => user.synced_at.strftime('%Y-%m-%dT%H:%M:%SZ')
    }
  end

  it 'includes accounts' do
    get('/profile', access_token: access_token.to_s).should be_ok
    parsed_body['accounts'].should == [{
      'id'          => user.id,
      'login'       => user.login,
      'name'        => user.name,
      'type'        => 'user',
      'reposCount'  => nil
    }]
  end
end
