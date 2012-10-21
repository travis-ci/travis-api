require 'spec_helper'

describe 'Users' do
  let(:user)    { Factory(:user, locale: 'en') }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  context 'PUT /users/:id' do
    it 'updates user data and returns the user' do
      params = {user: {id: user.id, locale: 'pl'}}
      response = put "/users/#{user.id}", params, headers
      response.should be_successful
      response.should deliver_json_for('result' => true, 'flash' => [{ 'notice' => 'Your profile was successfully updated.' }])
      user.reload.locale.should == 'pl'
    end
  end

  context 'POST /users/sync' do
    it 'syncs current_user repos' do
      response = post "/users/sync", {}, headers
      response.should be_successful
    end
  end
end

