require 'spec_helper'

describe 'Builds' do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:build)   { repo.builds.first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  it 'GET /builds.json?repository_id=1' do
    response = get '/builds.json', { repository_id: repo.id }, headers
    response.should deliver_json_for(repo.builds.order('id DESC'), version: 'v1')
  end

  it 'GET /builds/1.json' do
    response = get "/builds/#{build.id}.json", { include_config: true }, headers
    response.should deliver_json_for(build, version: 'v1')
  end

  it 'GET /builds/1?repository_id=1.json' do
    response = get "/builds/#{build.id}.json", { repository_id: repo.id, include_config: true }, headers
    response.should deliver_json_for(build, version: 'v1')
  end

  it 'GET /svenfuchs/minimal/builds.json' do
    response = get '/svenfuchs/minimal/builds.json', {}, headers
    response.should redirect_to('/repositories/svenfuchs/minimal/builds.json')
  end

  it 'GET /svenfuchs/minimal/builds/1.json' do
    response = get "/svenfuchs/minimal/builds/#{build.id}.json", {}, headers
    response.should redirect_to("/repositories/svenfuchs/minimal/builds/#{build.id}.json")
  end
end
