require 'spec_helper'

describe 'Builds' do
  before { Scenario.default }

  let(:repo)  { Repository.first }
  let(:build) { repo.builds.first }

  describe 'collection' do
    it 'GET /builds?repository_id=:repository_id' do
      response = get "/builds?repository_id=#{repo.id}"
      response.should deliver_json_for('builds/all', 'v1', repository_id: repo.id)
    end

    xit 'GET /:owner_name/:name/builds' do
      response = get '/svenfuchs/minimal/builds'
      response.should deliver_json_for('builds/all', 'v1', repository_id: repo.id)
    end

    xit 'GET /builds?repository_id=:repository_id (404)' do
      response = get "/builds?repository_id=0"
      response.should be_not_found
    end

    it 'GET /:owner_name/:name/builds (404)' do
      response = get '/rails/rails/builds'
      response.should be_not_found
    end
  end

  describe 'item' do
    it 'GET /builds/:id' do
      response = get("/builds/#{build.id}")
      response.should deliver_json_for('builds/one', 'v1', id: build.id)
    end

    xit 'GET /:owner_name/:name/builds/:id' do
      response = get "/svenfuchs/minimal/builds/#{build.id}"
      response.should deliver_json_for('builds/one', 'v1', id: build.id)
    end
  end
end
