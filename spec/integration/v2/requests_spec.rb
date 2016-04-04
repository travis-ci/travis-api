require 'spec_helper'
require 'json'

describe 'Requests' do
  let(:repo)    { Factory.create(:repository) }
  let(:request) { Factory.create(:request, repository: repo) }
  let(:user)    { Factory.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  describe 'GET /requests' do
    it 'fetches requests' do
      response = get '/requests', { repository_id: repo.id }, headers
      response.should deliver_json_for(repo.requests, version: 'v2', type: 'requests')
    end

    it 'returns an error response if repo can\'t be found' do
      response = get '/requests', { repository_id: 0 }, headers
      JSON.parse(response.body)['error'].should == "Repository could not be found"
    end

    it 'should accept limit option' do
      response = get '/requests', { repository_id: repo.id, limit: 50 }, headers
      response.should deliver_json_for(repo.requests, version: 'v2', type: 'requests')
    end
  end

  describe 'GET /requests/:id' do
    it 'fetches a request' do
      response = get "/requests/#{request.id}", {}, headers
      response.should deliver_json_for(request, version: 'v2', type: 'request')
    end
  end
end
