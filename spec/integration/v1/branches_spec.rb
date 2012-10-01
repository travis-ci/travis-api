require 'spec_helper'

describe 'Branches' do
  before { Scenario.default }

  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  it 'GET /branches?repository_id=:repository_id' do
    response = get '/branches', { repository_id: repo.id }, headers
    response.should deliver_json_for(repo.last_finished_builds_by_branches, version: 'v1', type: 'branches')
  end
end
