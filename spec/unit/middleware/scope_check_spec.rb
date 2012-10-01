require 'spec_helper'

describe Travis::Api::App::Middleware::ScopeCheck do
  include Travis::Testing::Stubs

  let :access_token do
    Travis::Api::App::AccessToken.create(user: user, scope: :foo, app_id: -1)
  end

  before do
    mock_app do
      use Travis::Api::App::Middleware::ScopeCheck
      get('/') { 'ok' }
      get('/token') { env['travis.access_token'].to_s }
    end

    User.stubs(:find).with(user.id).returns(user)
  end

  it 'lets through requests without a token' do
    get('/').should be_ok
    body.should == 'ok'
    headers['X-OAuth-Scopes'].should_not == 'foo'
  end

  describe 'sets associated scope properly' do
    it 'accepts Authorization token header' do
      get('/', {}, 'HTTP_AUTHORIZATION' => "token #{access_token}").should be_ok
      headers['X-OAuth-Scopes'].should == 'foo'
    end

    it 'accepts basic auth' do
      authorize access_token.to_s, 'x'
      get('/').should be_ok
      headers['X-OAuth-Scopes'].should == 'foo'
    end

    it 'accepts query parameters' do
      get('/', access_token: access_token.to_s).should be_ok
      headers['X-OAuth-Scopes'].should == 'foo'
    end
  end

  describe 'reject requests with an invalide token' do
    it 'rejects Authorization token header' do
      get('/', {}, 'HTTP_AUTHORIZATION' => "token foo").should_not be_ok
    end

    it 'rejects basic auth' do
      authorize 'foo', 'x'
      get('/').should_not be_ok
    end

    it 'rejects query parameters' do
      get('/', access_token: 'foo').should_not be_ok
    end
  end

  it 'sets env["travis.access_token"]' do
    authorize access_token.to_s, 'x'
    get('/token').body.should == access_token.to_s
  end
end