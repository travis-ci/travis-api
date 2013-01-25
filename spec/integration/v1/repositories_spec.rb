require 'spec_helper'

describe 'v1 repos' do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.1+json' } }

  it 'GET /repositories.json' do
    response = get '/repositories.json', {}, headers
    response.should deliver_json_for(Repository.timeline, version: 'v1')
  end

  it 'GET /repositories.json?owner_name=svenfuchs' do
    response = get '/repositories.json', { owner_name: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v1')
  end

  it 'GET /repositories.json?member=svenfuchs' do
    response = get '/repositories.json', { member: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_member('svenfuchs'), version: 'v1')
  end

  it 'GET /repositories.json?slug=svenfuchs/name=minimal' do
    response = get '/repositories.json', { slug: 'svenfuchs/minimal' }, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v1')
  end

  it 'GET /repositories/1.json' do
    response = get "repositories/#{repo.id}.json", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v1')
  end

  it 'GET /svenfuchs/minimal.json' do
    response = get '/svenfuchs/minimal.json', {}, headers
    response.should redirect_to('/repositories/svenfuchs/minimal.json')
  end

  it 'GET /svenfuchs/minimal/cc.xml' do
    response = get '/svenfuchs/minimal/cc.xml'
    response.should redirect_to('/repositories/svenfuchs/minimal/cc.xml')
  end

  describe 'GET /svenfuchs/minimal.png' do
    it '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has one build that is not finished' do
      Build.delete_all
      Factory(:build, repository: repo, state: :created, result: nil)
      repo.builds.update_all(state: 'started')
      get('/svenfuchs/minimal.png').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      repo.builds.update_all(state: 'failed')
      get('/svenfuchs/minimal.png').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      repo.builds.update_all(state: 'passed')
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: nil, previous_result: 0)
      repo.update_attributes!(last_build_state: 'started')
      get('/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end
  end

  describe 'GET /svenfuchs/minimal.png?branch=foo,bar' do
    let(:on_foo) { Factory(:commit, branch: 'foo') }
    let(:on_bar) { Factory(:commit, branch: 'bar') }

    it '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png?branch=foo,bar').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has unfinished builds on the relevant branches' do
      Build.delete_all
      Factory(:build, repository: repo, state: :started, commit: on_foo)
      Factory(:build, repository: repo, state: :started, commit: on_bar)
      get('/svenfuchs/minimal.png?branch=foo,bar').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :failed, commit: on_foo)
      Factory(:build, repository: repo, state: :failed, commit: on_bar)
      get('/svenfuchs/minimal.png?branch=foo,bar').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :failed, commit: on_foo)
      Factory(:build, repository: repo, state: :passed, commit: on_bar)
      get('/svenfuchs/minimal.png?branch=foo,bar').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :passed, commit: on_foo)
      Factory(:build, repository: repo, state: :passed, commit: on_bar)
      Factory(:build, repository: repo, state: :started, commit: on_bar)
      repo.update_attributes!(last_build_state: 'started')
      get('/svenfuchs/minimal.png?branch=foo,bar').should deliver_result_image_for('passing')
    end
  end
end
