require 'spec_helper'

describe 'Builds' do
  before { Scenario.default }

  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /builds?repository_id=1' do
    response = get '/builds', { repository_id: repo.id }, headers
    response.should deliver_json_for(repo.builds.order('id DESC'), version: 'v2')
  end

  it 'GET /builds/1' do
    response = get "/builds/#{build.id}", {}, headers
    response.should deliver_json_for(build, version: 'v2')
  end

  it 'GET /builds/1?repository_id=1' do
    response = get "/builds/#{build.id}", { repository_id: repo.id }, headers
    response.should deliver_json_for(build, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/builds' do
    response = get '/repos/svenfuchs/minimal/builds', {}, headers
    response.should deliver_json_for(repo.builds, version: 'v2', type: :builds)
  end

  it 'GET /repos/svenfuchs/minimal/builds/1' do
    response = get "/repos/svenfuchs/minimal/builds/#{build.id}", {}, headers
    response.should deliver_json_for(build, version: 'v2')
  end
end
