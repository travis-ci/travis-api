require 'spec_helper'

describe Travis::Api::App::Endpoint::Authorization do
  include Travis::Testing::Stubs

  before do
    add_endpoint '/info' do
      get '/login', scope: :private do
        env['travis.access_token'].user.login
      end
    end

    user.stubs(:github_id).returns(42)
    User.stubs(:find_github_id).returns(user)
    User.stubs(:find).returns(user)
  end

  describe 'GET /auth/authorize' do
    pending "not yet implemented"
  end

  describe 'POST /auth/access_token' do
    pending "not yet implemented"
  end

  describe 'POST /auth/github' do
    before do
      data = { 'id' => user.github_id, 'name' => user.name, 'login' => user.login, 'gravatar_id' => user.gravatar_id }
      GH.stubs(:with).with(token: 'private repos').returns stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'repo'}, :to_hash => data)
      GH.stubs(:with).with(token: 'public repos').returns  stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'public_repo'}, :to_hash => data)
      GH.stubs(:with).with(token: 'no repos').returns      stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'user'}, :to_hash => data)
      GH.stubs(:with).with(token: 'invalid token').raises(Faraday::Error::ClientError, 'CLIENT ERROR!')
    end

    def get_token(github_token)
      post('/auth/github', github_token: github_token).should be_ok
      parsed_body['access_token']
    end

    def user_for(github_token)
      get '/info/login', access_token: get_token(github_token)
      last_response.status.should == 200
      User.find_by_login(body)
    end

    it 'accepts tokens with repo scope' do
      user_for('private repos').name.should == user.name
    end

    it 'accepts tokens with public_repo scope' do
      user_for('public repos').name.should == user.name
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', github_token: 'no repos').should_not be_ok
      body.should_not include('access_token')
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', github_token: 'invalid token').should_not be_ok
      body.should_not include('access_token')
    end
  end
end
