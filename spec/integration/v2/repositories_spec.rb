# encoding: utf-8

describe 'Repos', set_app: true do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }
  let(:user)    { User.where(login: 'svenfuchs').first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

  it 'returns 403 if not authenticated' do
    repos = Repository.all
    ids = repos[0..1].map(&:id)
    response = get "/repos?ids=#{ids.join(',')}", {}, headers
    response.status.should ==  403
  end

  describe 'with authenticated user' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    it 'POST /repos/:id/key' do
      repo.regenerate_key!
      expect {
        response = post "/repos/#{repo.id}/key", {}, headers
      }.to change { repo.reload.key.private_key }
    end

    it 'POST /repos/:owner/:name/key' do
      repo.regenerate_key!
      expect {
        response = post "/repos/#{repo.slug}/key", {}, headers
      }.to change { repo.reload.key.private_key }
    end

    it 'allows to update settings' do
      json = { 'settings' => { 'build_pushes' => false } }.to_json
      response = patch "repos/#{repo.id}/settings", json, headers

      repo.reload.settings['build_pushes'].should == false

      body = JSON.parse(response.body)
      body['settings']['build_pushes'].should == false
    end

    it 'returns errors when settings are not valid' do
       json = { 'settings' => { 'maximum_number_of_builds' => 'this is not a number' } }.to_json
      response = patch "repos/#{repo.id}/settings", json, headers

      repo.reload.settings['maximum_number_of_builds'].should == 0

      body = JSON.parse(response.body)
      body['message'].should == 'Validation failed'
      body['errors'].should == [{
        'field' => 'maximum_number_of_builds',
        'code' => 'not_a_number'
      }]
    end

    it 'allows to get settings' do
      response = get "repos/#{repo.id}/settings", {}, headers
      JSON.parse(response.body)['settings'].should have_key('build_pushes')
      JSON.parse(response.body)['settings'].should_not have_key('env_vars')
    end

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
  end

  describe 'without authenticated user' do
    it 'POST /repos/:id/key' do
      response = post "/repos/#{repo.id}/key", {}, headers
      response.should be_not_found
    end

    it 'POST /repos/:owner/:name/key' do
      response = post "/repos/#{repo.id}/key", {}, headers
      response.should be_not_found
    end
  end

  it 'GET /repos/:id/key' do
    repo.regenerate_key!
    response = get "/repos/#{repo.id}/key", {}, headers
    response.should deliver_json_for(repo.key, version: 'v2')
  end

  it 'GET /repos/:slug/key' do
    repo.regenerate_key!
    response = get "/repos/#{repo.slug}/key", {}, headers
    response.should deliver_json_for(repo.key, version: 'v2')
  end

  it 'GET /repos' do
    response = get '/repos', {}, headers
    response.status.should == 403
  end

  it 'GET /repos/:owner' do
    response = get "repos/#{repo.owner.login}", {}, headers
    response.should deliver_json_for(Repository.by_owner_name(repo.owner.login), version: 'v2')
  end

  it 'GET /repos/1' do
    response = get "repos/#{repo.id}", {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/1/cc.xml' do
    response = get "repos/#{repo.id}/cc.xml"
    repo = Repository.by_slug('svenfuchs/minimal').first

    response.status.should == 200
    response.should deliver_cc_xml_for(repo)
    response.content_type.should eq('application/xml;charset=utf-8')
  end

  it '[.com, public mode] GET /repos/1/cc.xml fetches the xml when repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    response = get "repos/svenfuchs/minimal/cc.xml"
    response.status.should == 200
    response.should deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
    response.content_type.should eq('application/xml;charset=utf-8')
  end

  it '[.com, public mode] GET /repos/1/cc.xml responds with 302 when repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    repo = Repository.by_slug('svenfuchs/minimal').first
    repo.update_column(:private, true)

    response = get "repos/#{repo.id}/cc.xml"
    response.status.should == 404
  end

  it 'GET /repos/svenfuchs/minimal' do
    response = get '/repos/svenfuchs/minimal', {}, headers
    response.should deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/cc.xml' do
    response = get '/repos/svenfuchs/minimal/cc.xml'
    response.should deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
  end

  it 'responds 403 to /repos when no token is given' do
    response = get '/repos', {}, 'HTTP_ACCEPT' => 'application/xml; version=2'
    response.status.should == 403
  end

  it 'responds with 200 and an image if a repo exists and with browser-like accept header' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    Factory(:build, repository: repo, state: :passed)

    result = get('/svenfuchs/minimal.svg?branch=master', {}, 'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/svg+xml'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing.svg')
  end

  it 'responds with 200 and image when repo can\'t be found and format is png' do
    result = get('/repos/foo/bar', {}, 'HTTP_ACCEPT' => 'image/png')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('unknown')
  end

  it 'responds with 200 and image when repo can\'t be found and format is png' do
    result = get('/repos/foo/bar.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('unknown')
  end

  it '[.org, public_mode] responds with a passing image when the repo is public' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    Factory(:build, repository: repo, state: :passed)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it '[.com, public_mode] responds with a passing image when the repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true
    Factory(:build, repository: repo, state: :passed)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it '[.com, public_mode] responds with an unknown image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('unknown')
  end

  it '[.com, private mode] responds with a 404 when the repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, false)
    Factory(:build, repository: repo, state: :passed)
    result = get('/repos/svenfuchs/minimal.png', {})
    result.status.should == 401
  end

  it '[.com, private mode] responds with a 404 image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {})
    result.status.should == 401
  end

  it '[.com, private mode, authenticated] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_AUTHORIZATION' => "token #{token}")
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it '[.com, private mode, with token] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get("/repos/svenfuchs/minimal.png?token=#{user.tokens.first.token}")
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it '[.com, public mode, authenticated] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_AUTHORIZATION' => "token #{token}")
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it '[.com, public mode, with token] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    Factory(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get("/repos/svenfuchs/minimal.png?token=#{user.tokens.first.token}")
    result.status.should == 200
    result.headers['Content-Type'].should == 'image/png'
    result.body.should_not == ''
    result.should deliver_result_image_for('passing')
  end

  it 'responds with 404 when repo can\'t be found and format is other than png' do
    result = get('/repos/foo/bar', {}, 'HTTP_ACCEPT' => 'application/json; version=2')
    result.status.should == 404
    JSON.parse(result.body).should == { 'file' => 'not found' }
  end

  it 'GET /repos/svenfuchs/minimal/branches' do
    response = get '/repos/svenfuchs/minimal/branches', {}, headers
    response.should deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2', type: 'branches')
  end

  it 'GET /repos/1/branches' do
    response = get "/repos/#{repo.id}/branches", {}, headers
    response.should deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2', type: 'branches')
  end

  it 'GET /repos/svenfuchs/minimal/branches/mybranch' do
    mybuild = Factory(:build, repository: repo, state: :started, commit: Factory(:commit, branch: 'mybranch'), request: Factory(:request, event_type: 'push'))
    response = get "/repos/svenfuchs/minimal/branches/mybranch", {}, headers
    body = JSON.parse(response.body)
    body['branch']['id'].should == mybuild.id
  end

  it 'GET /repos/svenfuchs/minimal/branches/my/branch' do
    mybuild = Factory(:build, repository: repo, state: :started, commit: Factory(:commit, branch: 'my/branch'), request: Factory(:request, event_type: 'push'))
    response = get "/repos/svenfuchs/minimal/branches/my/branch", {}, headers
    body = JSON.parse(response.body)
    body['branch']['id'].should == mybuild.id
  end

  describe 'GET /repos/svenfuchs/minimal.png?branch=foo,bar' do
    let(:on_foo) { Factory(:commit, branch: 'foo') }
    let(:on_bar) { Factory(:commit, branch: 'bar') }

    it '"unknown" when it only has unfinished builds on the relevant branches' do
      Build.delete_all
      Factory(:build, repository: repo, state: :started, commit: on_foo)
      Factory(:build, repository: repo, state: :started, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      Factory(:build, repository: repo, state: :failed, commit: on_foo)
      Factory(:build, repository: repo, state: :failed, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      Factory(:build, repository: repo, state: :failed, commit: on_foo)
      Factory(:build, repository: repo, state: :passed, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('passing')
      result.headers['Last-Modified'].should == repo.last_build_finished_at.httpdate
    end

    it '"passing" when there is a running build but the previous one has passed' do
      Factory(:build, repository: repo, state: :passed, commit: on_foo)
      Factory(:build, repository: repo, state: :passed, commit: on_bar)
      Factory(:build, repository: repo, state: :started,  commit: on_bar)
      repo.update_attributes!(last_build_state: nil)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      result.should deliver_result_image_for('passing')
    end
  end

  context 'with "Accept: application/atom+xml" header' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/atom+xml' } }
    it 'GET /repositories/svenfuchs/minimal/builds' do
      response = get '/repositories/svenfuchs/minimal/builds', {}, headers
      response.content_type.should =~ /^application\/atom\+xml/
    end
  end

  context 'with .atom extension' do
    let(:headers) { { 'HTTP_ACCEPT' => '*/*' } }
    it 'GET /repositories/svenfuchs/minimal/builds.atom' do
      response = get '/repositories/svenfuchs/minimal/builds.atom', {}, headers
      response.content_type.should =~ /^application\/atom\+xml/
    end
  end
end
