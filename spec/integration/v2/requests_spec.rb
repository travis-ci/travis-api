require 'json'

describe 'Requests', set_app: true do
  let(:repo)    { FactoryBot.create(:repository) }
  let(:request) { FactoryBot.create(:request, repository: repo) }
  let(:build)   { FactoryBot.create(:build, repository: repo) }
  let(:user)    { FactoryBot.create(:user) }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

  before do
    Travis.config.billing.url = 'http://localhost:9292/'
    Travis.config.billing.auth_key = 'secret'

    stub_request(:post, /http:\/\/localhost:9292\/(users|organizations)\/(.+)\/authorize_build/).to_return(
      body: MultiJson.dump(allowed: true, rejection_code: nil)
    )
  end

  after do
    Travis.config.billing.url = nil
    Travis.config.billing.auth_key = nil
  end

  describe 'GET /requests' do
    it 'fetches requests' do
      response = get '/requests', { repository_id: repo.id }, headers
      expect(response).to deliver_json_for(repo.requests, version: 'v2', type: 'requests')
    end

    it 'returns an error response if repo can\'t be found' do
      response = get '/requests', { repository_id: 0 }, headers
      expect(JSON.parse(response.body)['error']).to eq("Repository could not be found")
    end
  end

  describe 'GET /requests/:id' do
    it 'fetches a request' do
      response = get "/requests/#{request.id}", {}, headers
      expect(response).to deliver_json_for(request, version: 'v2', type: 'request')
    end
  end

  describe 'POST /requests' do
    it 'triggers a build request using Hub' do
      response = post "/requests", { build_id: build.id }, headers
      expect(response.status).to be(200)
    end

    context 'when the repo is migrating' do
      before { repo.update(migration_status: "migrating") }
      before { post "/requests", { build_id: build.id }, headers }
      it { expect(last_response.status).to eq(403) }
    end

    context 'when the repo is migrated' do
      before { repo.update(migration_status: "migrated") }
      before { post "/requests", { build_id: build.id }, headers }
      it { expect(last_response.status).to eq(403) }
    end
  end

  it 'triggers a job request' do
    payload = { job_id: build.matrix.first.id, user_id: repo.owner.id }
    response = post "/requests", payload, headers
    expect(response.status).to be(200)
  end

end
