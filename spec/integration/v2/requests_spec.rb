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
  end

  describe 'GET /requests/:id' do
    it 'fetches a request' do
      response = get "/requests/#{request.id}", {}, headers
      response.should deliver_json_for(request, version: 'v2', type: 'request')
    end
  end

  describe 'POST /requests' do
    let(:payload) { { request: { repository: { owner_name: repo.owner_name, name: repo.name } } } }

    before do
      Travis::Features.stubs(:owner_active?).returns(true)
    end

    it 'schedules a request' do
      response = post '/requests', payload, headers
      expect(response.status).to eq 200
    end

    it 'requires activation' do
      Travis::Features.stubs(:owner_active?).returns(false)
      response = post '/requests', payload, headers
      json = JSON.parse(response.body)
      expect(json['result']).to eq 'not_active'
    end

    it 'throttles requests' do
      Travis::Api::App::Services::ScheduleRequest::Throttle.any_instance.stubs(:throttled?).returns(true)
      response = post '/requests', payload, headers
      json = JSON.parse(response.body)
      expect(json['result']).to eq 'throttled'
    end
  end
end
