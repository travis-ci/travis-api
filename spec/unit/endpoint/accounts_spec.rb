require 'spec_helper'

describe Travis::Api::App::Endpoint::Accounts do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

  before do
    User.stubs(:find_by_github_id).returns(user)
    User.stubs(:find).returns(user)
    user.stubs(:repositories).returns(stub(administratable: stub(select: [repository])))
    user.stubs(:attributes).returns(:id => user.id, :login => user.login, :name => user.name)
  end

  it 'includes accounts' do
    get('/accounts', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01').should be_ok
    parsed_body['accounts'].should == [{
      'id'          => user.id,
      'login'       => user.login,
      'name'        => user.name,
      'type'        => 'user',
      'reposCount'  => nil
    }]
  end
end
