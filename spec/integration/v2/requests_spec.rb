require 'json'

describe 'Requests', set_app: true do
  let(:repo)    { Factory.create(:repository) }
  let(:request) { Factory.create(:request, repository: repo) }
  let(:build)   { Factory.create(:build, repository: repo) }
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
    it 'triggers a build request using Core code' do
      response = post "/requests", { build_id: build.id }, headers
      response.status.should be(200)
    end

    it 'triggers a build request using Hub' do
      Travis::Features.activate_owner(:enqueue_to_hub, repo.owner)

      response = post "/requests", { build_id: build.id }, headers
      response.status.should be(200)
    end
  end
end
