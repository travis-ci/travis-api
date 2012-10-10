require 'spec_helper'

describe 'Users' do
  let(:user)    { Factory(:user, locale: 'en') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  it 'GET /workers' do
    params = {user: {id: user.id, locale: 'pl'}}
    response = put "/users/#{user.id}", params, headers
    response.should be_successful
    response.should deliver_json_for(user.reload, version: 'v2')
    user.locale.should == 'pl'
  end
end

