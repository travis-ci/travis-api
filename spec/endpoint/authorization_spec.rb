require 'spec_helper'

describe Travis::Api::App::Endpoint::Authorization do
  include Travis::Testing::Stubs

  before do
    add_endpoint '/info' do
      get '/login', scope: :private do
        env['travis.access_token'].user.login
      end
    end

    User.stubs(:find_by_login).with(user.login).returns(user)
    User.stubs(:find).with(user.id).returns(user)
  end

  describe 'GET /auth/authorize' do
    pending "not yet implemented"
  end

  describe 'POST /auth/access_token' do
    pending "not yet implemented"
  end

  describe 'POST /auth/github' do
    before do
      GH.stubs(:with).with(token: 'private repos').returns stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'repo'})
      GH.stubs(:with).with(token: 'public repos').returns  stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'public_repo'})
      GH.stubs(:with).with(token: 'no repos').returns      stub(:[] => user.login, :headers => {'x-oauth-scopes' => 'user'})
      GH.stubs(:with).with(token: 'invalid token').raises(Faraday::Error::ClientError, 'CLIENT ERROR!')
    end

    def get_token(github_token)
      post('/auth/github', token: github_token).should be_ok
      parsed_body['access_token']
    end

    def user_for(github_token)
      get '/info/login', access_token: get_token(github_token)
      last_response.status.should == 200
      User.find_by_login(body)
    end

    it 'accepts tokens with repo scope' do
      user_for('private repos').should == user
    end

    it 'accepts tokens with public_repo scope' do
      user_for('public repos').should == user
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', token: 'no repos').should_not be_ok
      body.should_not include('access_token')
    end

    it 'rejects tokens with user scope' do
      post('/auth/github', token: 'invalid token').should_not be_ok
      body.should_not include('access_token')
    end
  end
end
