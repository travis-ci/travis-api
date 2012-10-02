require 'spec_helper'

describe 'Repos' do
  before(:each) { Scenario.default }

  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /repositories' do
    response = get '/repositories', {}, headers
    response.should deliver_json_for(Repository.timeline, version: 'v2')
  end

  it 'GET /repositories?owner_name=svenfuchs' do
    response = get '/repositories', { owner_name: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v2')
  end

  it 'GET /repositories?member=svenfuchs' do
    response = get '/repositories', { member: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_member('svenfuchs'), version: 'v2')
  end

  it 'GET /repositories?slug=svenfuchs/name=minimal' do
    response = get '/repositories', { slug: 'svenfuchs/minimal' }, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v2')
  end

  it 'GET /repositories/1' do
    response = get "repositories/#{repo.id}", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  xit 'GET /svenfuchs/minimal' do
    response = get '/svenfuchs/minimal', {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  xit 'GET /svenfuchs/minimal/cc.xml' do # TODO wat.
    response = get '/svenfuchs/minimal/cc.xml'
    response.should deliver_xml_for()
  end
end
