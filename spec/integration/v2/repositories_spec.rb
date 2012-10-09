require 'spec_helper'

describe 'Repos' do
  before(:each) { Scenario.default }

  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }

  it 'GET /repos' do
    response = get '/repos', {}, headers
    response.should deliver_json_for(Repository.timeline, version: 'v2')
  end

  it 'GET /repos?owner_name=svenfuchs' do
    response = get '/repos', { owner_name: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v2')
  end

  it 'GET /repos?member=svenfuchs' do
    response = get '/repos', { member: 'svenfuchs' }, headers
    response.should deliver_json_for(Repository.by_member('svenfuchs'), version: 'v2')
  end

  it 'GET /repos?slug=svenfuchs/name=minimal' do
    response = get '/repos', { slug: 'svenfuchs/minimal' }, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v2')
  end

  it 'GET /repos/1' do
    response = get "repos/#{repo.id}", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal' do
    response = get '/repos/svenfuchs/minimal', {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  xit 'GET /repos/svenfuchs/minimal/cc.xml' do
    response = get '/repos/svenfuchs/minimal/cc.xml', {}, headers
    response.should deliver_xml_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  describe 'GET /repos/svenfuchs/minimal.png' do
    it '"unknown" when the repository does not exist' do
      get('/svenfuchs/does-not-exist.png').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has one build that is not finished' do
      Build.delete_all
      Factory(:build, repository: repo, state: :created, result: nil)
      repo.update_attributes!(last_build_result: nil)
      get('/repos/svenfuchs/minimal.png').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      repo.update_attributes!(last_build_result: 1)
      get('/repos/svenfuchs/minimal.png').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      repo.update_attributes!(last_build_result: 0)
      get('/repos/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: nil, previous_result: 0)
      repo.update_attributes!(last_build_result: nil)
      get('/repos/svenfuchs/minimal.png').should deliver_result_image_for('passing')
    end
  end

  describe 'GET /repos/svenfuchs/minimal.png?branch=dev' do
    let(:commit) { Factory(:commit, branch: 'dev') }

    it '"unknown" when the repository does not exist' do
      get('/repos/svenfuchs/does-not-exist.png?branch=dev').should deliver_result_image_for('unknown')
    end

    it '"unknown" when it only has a build that is not finished' do
      Build.delete_all
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      get('/repos/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :finished, result: 1, commit: commit)
      get('/repos/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      get('/repos/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :finished, result: 0, commit: commit)
      Factory(:build, repository: repo, state: :started, result: nil, commit: commit)
      repo.update_attributes!(last_build_result: nil)
      get('/repos/svenfuchs/minimal.png?branch=dev').should deliver_result_image_for('passing')
    end
  end
end
