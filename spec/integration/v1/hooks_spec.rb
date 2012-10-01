require 'spec_helper'

describe 'Hooks' do
  before(:each) do
    Scenario.default
    user.permissions.create repository: repo, admin: true
  end

  let(:user)    { User.where(login: 'svenfuchs').first }
  let(:repo)    { Repository.first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  it 'GET /hooks' do
    response = get '/hooks', {}, headers
    response.should deliver_json_for(user.service_hooks, version: 'v1', type: 'hooks')
  end
end
