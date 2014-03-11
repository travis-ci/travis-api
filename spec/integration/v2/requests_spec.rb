require 'spec_helper'

describe 'Requests' do
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'fetches requests' do
    repo =    Factory.create(:repository)
    request = Factory.create(:request, repository: repo)

    response = get '/requests', { repository_id: repo.id }, headers
    response.should deliver_json_for(repo.requests, version: 'v2', type: 'requests')
  end

  it 'returns an error response if repo can\'t be found' do
    response = get '/requests', { repository_id: 0 }, headers
    JSON.parse(response.body)['error'].should == "Repository could not be found"
  end
end
