require 'spec_helper'

describe 'App' do
  before do
    FactoryGirl.create(:test, :number => '3.1', :queue => 'builds.common')

    add_endpoint '/foo' do
      get '/hash', scope: [:foo, :bar] do
        respond_with foo: 'bar'
      end

      get '/:job_id/log' do
        respond_with job_id: params[:job_id]
      end
    end
  end

  it 'checks if token has one of the required scopes' do
    token = Travis::Api::App::AccessToken.new(app_id: 1, user_id: 2, scopes: [:foo]).tap(&:save)

    response = get '/foo/hash', {}, 'HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => "token #{token.token}"
    response.should be_successful
    response.headers['X-Accepted-OAuth-Scopes'].should == 'foo'

    token = Travis::Api::App::AccessToken.new(app_id: 1, user_id: 2, scopes: [:bar]).tap(&:save)

    response = get '/foo/hash', {}, 'HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => "token #{token.token}"
    response.should be_successful
    response.headers['X-Accepted-OAuth-Scopes'].should == 'bar'

    token = Travis::Api::App::AccessToken.new(app_id: 1, user_id: 2, scopes: [:baz]).tap(&:save)

    response = get '/foo/hash', {}, 'HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => "token #{token.token}"
    response.status.should == 403
  end

  it 'checks if required_params match the from the request' do
    extra = {
      required_params: { job_id: '10' }
    }
    token = Travis::Api::App::AccessToken.new(app_id: 1, user_id: 2, extra: extra).tap(&:save)

    response = get '/foo/10/log', {}, 'HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => "token #{token.token}"
    response.should be_successful

    response = get '/foo/11/log', {}, 'HTTP_ACCEPT' => 'application/json', 'HTTP_AUTHORIZATION' => "token #{token.token}"
    response.status.should == 403
  end
end
