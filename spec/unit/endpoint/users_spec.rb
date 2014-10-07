require 'spec_helper'

describe Travis::Api::App::Endpoint::Users do
  include Travis::Testing::Stubs
  let(:access_token) { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }

  before do
    User.stubs(:find_by_github_id).returns(user)
    User.stubs(:find).returns(user)
    user.stubs(:repositories).returns(stub(administratable: stub(select: [repository])))
  end

  it 'needs to be authenticated' do
    get('/users', {}, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01').should_not be_ok
  end

  it 'replies with the current user' do
    get('/users', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01').should be_ok
    parsed_body['user'].should == {
      'id'             => user.id,
      'login'          => user.login,
      'name'           => user.name,
      'email'          => user.email,
      'gravatar_id'    => user.gravatar_id,
      'locale'         => user.locale,
      'is_syncing'     => user.is_syncing,
      'created_at'     => user.created_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'synced_at'      => user.synced_at.strftime('%Y-%m-%dT%H:%M:%SZ'),
      'correct_scopes' => true,
    }
  end

  context 'when responding to POST for /users/sync' do
    context 'when sync is in progress' do
      before :each do
        user.stubs(:syncing?).returns(true)
      end

      it 'returns 409' do
        response = post('/users/sync', { access_token: access_token.to_s }, 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json, */*; q=0.01')

        response.status.should == 409
        JSON.parse(response.body).should == { 'message' => 'Sync already in progress. Try again later.' }
      end
    end
  end
end
