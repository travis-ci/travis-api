# encoding: utf-8

describe 'Repos', set_app: true do
  let(:repo)    { Repository.by_slug('svenfuchs/minimal').first }
  let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json' } }
  let(:user)    { User.where(login: 'svenfuchs').first }
  let(:token)   { Travis::Api::App::AccessToken.create(user: user, app_id: -1) }
  before { user.permissions.create!(:repository_id => repo.id, :admin => true, :push => true) }

  let(:authorization) { { 'permissions' => ['repository_settings_create', 'repository_settings_update', 'repository_state_update', 'repository_settings_delete', 'repository_settings_read'] } }
  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  it 'returns 403 if not authenticated' do
    repos = Repository.all
    ids = repos[0..1].map(&:id)
    response = get "/repos?ids=#{ids.join(',')}", {}, headers
    expect(response.status).to eq(403)
  end

  describe 'with authenticated user' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/vnd.travis-ci.2+json', 'HTTP_AUTHORIZATION' => "token #{token}" } }

    context 'when the repo is migrating' do
      before { repo.update(migration_status: "migrating") }

      it "responds with 403" do
        response = post "/repos/#{repo.id}/key", {}, headers
        expect(response.status).to eq(403)

        response = post "/repos/#{repo.slug}/key", {}, headers
        expect(response.status).to eq(403)
      end
    end

    context 'when the repo is migrated' do
      before { repo.update(migration_status: "migrated") }

      it "responds with 403" do
        response = post "/repos/#{repo.id}/key", {}, headers
        expect(response.status).to eq(403)

        response = post "/repos/#{repo.slug}/key", {}, headers
        expect(response.status).to eq(403)
      end
    end

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

      expect(repo.reload.settings['build_pushes']).to eq(false)

      body = JSON.parse(response.body)
      expect(body['settings']['build_pushes']).to eq(false)
    end

    it 'returns errors when settings are not valid' do
       json = { 'settings' => { 'maximum_number_of_builds' => 'this is not a number' } }.to_json
      response = patch "repos/#{repo.id}/settings", json, headers

      expect(repo.reload.settings['maximum_number_of_builds']).to eq(0)

      body = JSON.parse(response.body)
      expect(body['message']).to eq('Validation failed')
      expect(body['errors']).to eq([{
        'field' => 'maximum_number_of_builds',
        'code' => 'not_a_number'
      }])
    end

    it 'allows to get settings' do
      response = get "repos/#{repo.id}/settings", {}, headers
      expect(JSON.parse(response.body)['settings']).to have_key('build_pushes')
      expect(JSON.parse(response.body)['settings']).not_to have_key('env_vars')
    end

    it 'GET /repos' do
      response = get '/repos', {}, headers
      expect(response).to deliver_json_for(Repository.timeline, version: 'v2')
    end

    it 'GET /repos?owner_name=svenfuchs' do
      response = get '/repos', { owner_name: 'svenfuchs' }, headers
      expect(response).to deliver_json_for(Repository.by_owner_name('svenfuchs'), version: 'v2')
    end

    it 'GET /repos?member=svenfuchs' do
      response = get '/repos', { member: 'svenfuchs' }, headers
      expect(response).to deliver_json_for(Repository.by_member('svenfuchs'), version: 'v2')
    end

    it 'GET /repos?slug=svenfuchs/name=minimal' do
      response = get '/repos', { slug: 'svenfuchs/minimal' }, headers
      expect(response).to deliver_json_for(Repository.by_slug('svenfuchs/minimal'), version: 'v2')
    end
  end

  describe 'without authenticated user' do
    it 'POST /repos/:id/key' do
      response = post "/repos/#{repo.id}/key", {}, headers
      expect(response).to be_not_found
    end

    it 'POST /repos/:owner/:name/key' do
      response = post "/repos/#{repo.id}/key", {}, headers
      expect(response).to be_not_found
    end
  end

  it 'GET /repos/:id/key' do
    repo.regenerate_key!
    response = get "/repos/#{repo.id}/key", {}, headers
    expect(response).to deliver_json_for(repo.key, version: 'v2')
  end

  it 'GET /repos/:slug/key' do
    repo.regenerate_key!
    response = get "/repos/#{repo.slug}/key", {}, headers
    expect(response).to deliver_json_for(repo.key, version: 'v2')
  end

  it 'GET /repos' do
    response = get '/repos', {}, headers
    expect(response.status).to eq(403)
  end

  it 'GET /repos/:owner' do
    response = get "repos/#{repo.owner.login}", {}, headers
    expect(response).to deliver_json_for(Repository.by_owner_name(repo.owner.login), version: 'v2')
  end

  it 'GET /repos/1' do
    response = get "repos/#{repo.id}", {}, headers
    expect(response).to deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/1/cc.xml' do
    response = get "repos/#{repo.id}/cc.xml"
    repo = Repository.by_slug('svenfuchs/minimal').first

    expect(response.status).to eq(200)
    expect(response).to deliver_cc_xml_for(repo)
    expect(response.content_type).to eq('application/xml;charset=utf-8')
  end

  it '[.com, public mode] GET /repos/1/cc.xml fetches the xml when repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    response = get "repos/svenfuchs/minimal/cc.xml"
    expect(response.status).to eq(200)
    expect(response).to deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
    expect(response.content_type).to eq('application/xml;charset=utf-8')
  end

  it '[.com, public mode] GET /repos/1/cc.xml responds with 302 when repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    repo = Repository.by_slug('svenfuchs/minimal').first
    repo.update_column(:private, true)

    response = get "repos/#{repo.id}/cc.xml"
    expect(response.status).to eq(404)
  end

  it 'GET /repos/svenfuchs/minimal' do
    response = get '/repos/svenfuchs/minimal', {}, headers
    expect(response).to deliver_json_for(Repository.by_slug('svenfuchs/minimal').first, version: 'v2')
  end

  it 'GET /repos/svenfuchs/minimal/cc.xml' do
    response = get '/repos/svenfuchs/minimal/cc.xml'
    expect(response).to deliver_cc_xml_for(Repository.by_slug('svenfuchs/minimal').first)
  end

  it 'responds 403 to /repos when no token is given' do
    response = get '/repos', {}, 'HTTP_ACCEPT' => 'application/xml; version=2'
    expect(response.status).to eq(403)
  end

  it 'does not proxy to .com if a user agent is set to PROXY_USER_AGENT' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    repo.update(migration_status: 'migrated', migrated_at: Time.now)
    FactoryBot.create(:build, repository: repo, state: :passed)

    headers = {
      'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8',
      'HTTP_USER_AGENT' => Travis::Api::App::Responders::Image::PROXY_USER_AGENT
    }

    result = get('/svenfuchs/minimal.svg?branch=master', {}, headers)
    expect(result.status).to eq(200)
    expect(result.body).not_to eq('an image')
  end

  it 'proxies to .com if a repo has been migrated' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    repo.update(migration_status: 'migrated', migrated_at: Time.now)
    FactoryBot.create(:build, repository: repo, state: :passed)

    stub_request(:get, "https://api.travis-ci.com/svenfuchs/minimal.svg?branch=master").
      with(headers: { 'Accept' => 'image/svg+xml' }).
      to_return(status: 200, body: 'an image')

    result = get('/svenfuchs/minimal.svg?branch=master', {}, 'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
  end

  it 'proxies to .com and an image if a repo has been migrated and with browser-like accept header' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    repo.update(migration_status: 'migrated', migrated_at: Time.now)
    FactoryBot.create(:build, repository: repo, state: :passed)

    stub_request(:get, "https://api.travis-ci.com/svenfuchs/minimal.svg?branch=master").
      with(headers: { 'Accept' => 'image/svg+xml' }).
      to_return(status: 200, body: 'an image')

    result = get('/svenfuchs/minimal.svg?branch=master', {}, 'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
  end

  it 'proxies to .com to .com if a repo has been migrated, slug without format' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    repo.update(migration_status: 'migrated', migrated_at: Time.now)
    FactoryBot.create(:build, repository: repo, state: :passed)

    stub_request(:get, "https://api.travis-ci.com/svenfuchs/minimal?branch=master").
      with(headers: { 'Accept' => 'image/svg+xml' }).
      to_return(status: 200, body: 'an image')

    result = get('/svenfuchs/minimal?branch=master', {}, 'HTTP_ACCEPT' => 'image/svg+xml')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
  end

  it 'does not proxy to .org if a user agent is set to PROXY_USER_AGENT' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true
    repo.update(migration_status: 'migrated', migrated_at: Time.now)
    FactoryBot.create(:build, repository: repo, state: :passed)

    headers = {
      'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8',
      'HTTP_USER_AGENT' => Travis::Api::App::Responders::Image::PROXY_USER_AGENT
    }

    result = get('/svenfuchs/minimal.svg?branch=master', {}, headers)
    expect(result.status).to eq(200)
    expect(result.body).not_to eq('an image')
  end

  it 'proxies to .org if a repo has not been migrated and is not active' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true
    repo.update(migration_status: nil, migrated_at: Time.now, active: false)
    FactoryBot.create(:build, repository: repo, state: :passed)

    stub_request(:get, "https://api.travis-ci.org/svenfuchs/minimal.svg?branch=master").
      with(headers: { 'Accept' => 'image/svg+xml' }).
      to_return(status: 200, body: 'an image')

    result = get('/svenfuchs/minimal.svg?branch=master', {}, 'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
    expect(result.headers['X-Badge-Location']).to eq("https://api.travis-ci.org/svenfuchs/minimal.svg?branch=master")
  end

  it 'responds with 200 and an image if a repo exists and with browser-like accept header' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    FactoryBot.create(:build, repository: repo, state: :passed)

    result = get('/svenfuchs/minimal.svg?branch=master', {}, 'HTTP_ACCEPT' => 'image/webp,image/apng,image/*,*/*;q=0.8')
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/svg+xml')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing.svg')
  end

  it 'proxies to .com and image when repo can\'t be found and format is png' do
    stub_request(:get, "https://api.travis-ci.com/foo/bar").
      with(headers: { 'Accept' => 'image/png' }).
      to_return(status: 200, body: 'an image')

    result = get('/repos/foo/bar', {}, 'HTTP_ACCEPT' => 'image/png')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
  end

  it 'proxies to .com and image when repo can\'t be found and format is png' do
    stub_request(:get, "https://api.travis-ci.com/foo/bar.png").
      with(headers: { 'Accept' => 'image/png' }).
      to_return(status: 200, body: 'an image')

    result = get('/repos/foo/bar.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    expect(result.status).to eq(200)
    expect(result.body).to eq('an image')
  end

  it '[.org, public_mode] responds with a passing image when the repo is public' do
    Travis.config.host = 'travis-ci.org'
    Travis.config.public_mode = true
    FactoryBot.create(:build, repository: repo, state: :passed)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it '[.com, public_mode] responds with a passing image when the repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true
    FactoryBot.create(:build, repository: repo, state: :passed)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it '[.com, public_mode] responds with an unknown image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_ACCEPT' => 'image/png; version=2')
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('unknown')
  end

  it '[.com, private mode] responds with a 404 when the repo is public' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, false)
    FactoryBot.create(:build, repository: repo, state: :passed)
    result = get('/repos/svenfuchs/minimal.png', {})
    expect(result.status).to eq(401)
  end

  it '[.com, private mode] responds with a 404 image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {})
    expect(result.status).to eq(401)
  end

  it '[.com, private mode, authenticated] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_AUTHORIZATION' => "token #{token}")
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it '[.com, private mode, with token] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = false

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get("/repos/svenfuchs/minimal.png?token=#{user.tokens.first.token}")
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it '[.com, public mode, authenticated] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get('/repos/svenfuchs/minimal.png', {}, 'HTTP_AUTHORIZATION' => "token #{token}")
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it '[.com, public mode, with token] responds with a passing image when the repo is private' do
    Travis.config.host = 'travis-ci.com'
    Travis.config.public_mode = true

    FactoryBot.create(:build, repository: repo, state: :passed)
    Repository.by_slug('svenfuchs/minimal').first.update_column(:private, true)

    result = get("/repos/svenfuchs/minimal.png?token=#{user.tokens.first.token}")
    expect(result.status).to eq(200)
    expect(result.headers['Content-Type']).to eq('image/png')
    expect(result.body).not_to eq('')
    expect(result).to deliver_result_image_for('passing')
  end

  it 'responds with 404 when repo can\'t be found and format is other than png' do
    result = get('/repos/foo/bar', {}, 'HTTP_ACCEPT' => 'application/json; version=2')
    expect(result.status).to eq(404)
    expect(JSON.parse(result.body)).to eq({ 'file' => 'not found' })
  end

  it 'GET /repos/svenfuchs/minimal/branches' do
    response = get '/repos/svenfuchs/minimal/branches', {}, headers
    expect(response).to deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2', type: 'branches')
  end

  it 'GET /repos/1/branches' do
    response = get "/repos/#{repo.id}/branches", {}, headers
    expect(response).to deliver_json_for(repo.last_finished_builds_by_branches, version: 'v2', type: 'branches')
  end

  it 'GET /repos/svenfuchs/minimal/branches/mybranch' do
    mybuild = FactoryBot.create(:build, repository: repo, state: :started, commit: FactoryBot.create(:commit, branch: 'mybranch'), request: FactoryBot.create(:request, event_type: 'push'))
    response = get "/repos/svenfuchs/minimal/branches/mybranch", {}, headers
    body = JSON.parse(response.body)
    expect(body['branch']['id']).to eq(mybuild.id)
  end

  it 'GET /repos/svenfuchs/minimal/branches/my/branch' do
    mybuild = FactoryBot.create(:build, repository: repo, state: :started, commit: FactoryBot.create(:commit, branch: 'my/branch'), request: FactoryBot.create(:request, event_type: 'push'))
    response = get "/repos/svenfuchs/minimal/branches/my/branch", {}, headers
    body = JSON.parse(response.body)
    expect(body['branch']['id']).to eq(mybuild.id)
  end

  describe 'GET /repos/svenfuchs/minimal.png?branch=foo,bar' do
    let(:on_foo) { FactoryBot.create(:commit, branch: 'foo') }
    let(:on_bar) { FactoryBot.create(:commit, branch: 'bar') }

    it '"unknown" when it only has unfinished builds on the relevant branches' do
      Build.delete_all
      FactoryBot.create(:build, repository: repo, state: :started, commit: on_foo)
      FactoryBot.create(:build, repository: repo, state: :started, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      expect(result).to deliver_result_image_for('unknown')
    end

    it '"failing" when the last build has failed' do
      FactoryBot.create(:build, repository: repo, state: :failed, commit: on_foo)
      FactoryBot.create(:build, repository: repo, state: :failed, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      expect(result).to deliver_result_image_for('failing')
    end

    it '"passing" when the last build has passed' do
      FactoryBot.create(:build, repository: repo, state: :failed, commit: on_foo)
      FactoryBot.create(:build, repository: repo, state: :passed, commit: on_bar)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      expect(result).to deliver_result_image_for('passing')
      expect(result.headers['Last-Modified']).to eq(repo.last_build_finished_at.httpdate)
    end

    it '"passing" when there is a running build but the previous one has passed' do
      FactoryBot.create(:build, repository: repo, state: :passed, commit: on_foo)
      FactoryBot.create(:build, repository: repo, state: :passed, commit: on_bar)
      FactoryBot.create(:build, repository: repo, state: :started,  commit: on_bar)
      repo.update!(last_build_state: nil)
      result = get('/repos/svenfuchs/minimal.png?branch=foo,bar', {}, headers)
      expect(result).to deliver_result_image_for('passing')
    end
  end

  context 'with "Accept: application/atom+xml" header' do
    let(:headers) { { 'HTTP_ACCEPT' => 'application/atom+xml' } }
    it 'GET /repositories/svenfuchs/minimal/builds' do
      response = get '/repositories/svenfuchs/minimal/builds', {}, headers
      expect(response.content_type).to match(/^application\/atom\+xml/)
    end
  end

  context 'with .atom extension' do
    let(:headers) { { 'HTTP_ACCEPT' => '*/*' } }
    it 'GET /repositories/svenfuchs/minimal/builds.atom' do
      response = get '/repositories/svenfuchs/minimal/builds.atom', {}, headers
      expect(response.content_type).to match(/^application\/atom\+xml/)
    end
  end
end
