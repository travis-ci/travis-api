describe 'v2 repos', auth_helpers: true, api_version: :v2, set_app: true do
  let(:user)  { FactoryBot.create(:user) }
  let(:repo)  { Repository.by_slug('svenfuchs/minimal').first }
  let(:build) { repo.builds.first }

  before(:all) { SslKey.create(repository_id: 1) }
  before { SslKey.update_all(repository_id: repo.id) }

  let(:authorization) { { 'permissions' => ['repository_settings_create', 'repository_settings_update', 'repository_state_update', 'repository_settings_delete', 'repository_settings_read' ,'repository_cache_view'] } }
  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/permissions/repo/)).to_return(status: 404, body: JSON.generate(authorization)) }

  # TODO
  # patch '/repos/:id/settings'
  # post '/repos/:id/key' }
  # delete '/:repository_id/caches'
  # post '/:owner_name/:name/key'

  describe 'in public mode, with a private repo', mode: :public, repo: :private do
    describe 'GET /repos' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{user.login}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/settings' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/caches' do
      include_context 'cache setup'
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 403, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in public mode, with a public repo', mode: :public, repo: :public do
    describe 'GET /repos' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{user.login}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/settings' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/caches' do
      include_context 'cache setup'
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 403, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in private mode, with a public repo', mode: :private, repo: :public do
    describe 'GET /repos' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{user.login}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/settings' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/caches' do
      include_context 'cache setup'
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 403, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  # +----------------------------------------------------+
  # |                                                    |
  # |   !!! THE ORIGINAL BEHAVIOUR ... DON'T TOUCH !!!   |
  # |                                                    |
  # +----------------------------------------------------+

  describe 'in private mode, with a private repo', mode: :private, repo: :private do
    describe 'GET /repos' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{user.login}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/settings' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/caches' do
      include_context 'cache setup'
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 403, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.slug}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 401 }
    end
  end

  describe 'in org mode, with a public repo', mode: :org, repo: :public do
    describe 'GET /repos' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 403 }
    end

    describe 'GET /repos/%{user.login}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}/settings' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 404 }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.id}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}/caches' do
      include_context 'cache setup'
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 403, type: :json, empty: true }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 404 }
    end

    describe 'GET /repos/%{repo.slug}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/builds' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/builds?branches=' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/builds/%{build.id}' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/key' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.slug}/branches' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end

    describe 'GET /repos/%{repo.id}/branches/master' do
      it(:with_permission)    { should auth status: 200, type: :json, empty: false }
      it(:without_permission) { should auth status: 200, type: :json, empty: false }
      it(:invalid_token)      { should auth status: 403 }
      it(:unauthenticated)    { should auth status: 200, type: :json, empty: false }
    end
  end
end
