require 'spec_helper'

describe 'Repos' do
  before(:each) { Scenario.default }

  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  it 'GET /repositories' do
    response = get '/repositories', {}, headers
    response.should deliver_json_for(Repository.timeline, version: 'v1')
  end

  it 'GET /repositories?owner_name=svenfuchs' do
    response = get '/repositories', { owner_name: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v1')
  end

  it 'GET /repositories?member=svenfuchs' do
    response = get '/repositories', { member: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_member('svenfuchs'), version: 'v1')
  end

  it 'GET /repositories?slug=svenfuchs/name=minimal' do
    response = get '/repositories', { slug: 'svenfuchs/minimal' }, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v1')
  end

  it 'GET /repositories/1' do
    response = get "repositories/#{repo.id}", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v1')
  end

  xit 'GET /svenfuchs/minimal' do
    response = get '/svenfuchs/minimal', {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v1')
  end

  xit 'GET /svenfuchs/minimal/cc.xml' do # TODO wat.
    response = get '/svenfuchs/minimal/cc.xml'
    response.should deliver_xml_for()
  end

  describe 'GET /svenfuchs/minimal.png' do
    xit '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png').should deliver_result_image_for('unknown')
    end

    xit '"unknown" when it only has one build that is not finished' do
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('unknown')
    end

    xit '"failing" when the last build has failed' do
      repo.update_attributes!(last_build_result: 1)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('failing')
    end

    xit '"passing" when the last build has passed' do
      repo.update_attributes!(last_build_result: 0)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end

    xit '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: nil, previous_result: 0)
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end
  end

  describe 'GET /svenfuchs/minimal.png' do
    let(:commit) { Factory(:commit, branch: 'dev') }

    xit '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png?branch=dev').should deliver_result_image_for('unknown')
    end

    xit '"unknown" when it only has a build that is not finished' do
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('unknown')
    end

    xit '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :finished, result: 1, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('failing')
    end

    xit '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end

    xit '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      repo.update_attributes!(last_build_result: nil)
      get('/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end
  end
end
