describe Travis::API::V3::Services::UserSettings::ForRepository, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true, push: true, admin: false) }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/settings") }
    include_examples 'not authenticated'
  end

  describe 'authenticated as wrong user'

  describe 'authenticated, missing repo' do
    before { get('/v3/repo/9999999999/settings', {}, auth_headers) }

    example { expect(last_response.status).to eq(404) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_type' => 'not_found',
        'error_message' => 'repository not found (or insufficient access)',
        'resource_type' => 'repository'
      )
    end
  end

  before { Travis::Features.activate_owner(:auto_cancel, repo.owner) }
  after  { Travis::Features.deactivate_owner(:auto_cancel, repo.owner) }

  describe 'authenticated, existing repo, repo has no settings, return defaults' do
    describe 'a public repo' do
      before { get("/v3/repo/#{repo.id}/settings", {}, auth_headers) }

      example { expect(last_response.status).to eq(200) }

      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'settings',
          '@href' => "/v3/repo/#{repo.id}/settings",
          '@representation' => 'standard',
          'settings' => [
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'builds_only_with_travis_yml', 'value' => false },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",                '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'build_pushes',                'value' => true },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests",         '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'build_pull_requests',         'value' => true },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds",    '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'maximum_number_of_builds',    'value' => 0 },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pushes",          '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'auto_cancel_pushes',          'value' => false },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pull_requests",   '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'auto_cancel_pull_requests',   'value' => false },
            { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/config_validation",           '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'config_validation',           'value' => false },
          ]
        )
      end
    end

    describe 'a private repo' do
      before { repo.update_attributes!(private: true) }
      before { get("/v3/repo/#{repo.id}/settings", {}, auth_headers) }

      example do
        expect(JSON.load(body)['settings']).to include(
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => true }, '@href' => "/v3/repo/#{repo.id}/setting/allow_config_imports", '@representation' => 'standard', 'name' => 'allow_config_imports', 'value' => false },
        )
      end
    end
  end

  describe 'authenticated, existing repo, repo has some settings' do
    before do
      repo.update_attributes(settings: { 'build_pushes' => false })
      get("/v3/repo/#{repo.id}/settings", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'settings',
        '@href' => "/v3/repo/#{repo.id}/settings",
        '@representation' => 'standard',
        'settings' => [
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'builds_only_with_travis_yml', 'value' => false },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",                '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'build_pushes',                'value' => false },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests",         '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'build_pull_requests',         'value' => true },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds",    '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'maximum_number_of_builds',    'value' => 0 },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pushes",          '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'auto_cancel_pushes',          'value' => false },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pull_requests",   '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'auto_cancel_pull_requests',   'value' => false },
          { '@type' => 'setting', '@href' => "/v3/repo/#{repo.id}/setting/config_validation",           '@representation' => 'standard', '@permissions' => { 'read' => true, 'write' => true }, 'name' => 'config_validation',           'value' => false },
        ]
      )
    end
  end

  describe 'authenticated, existing repo, update one setting' do
    before do
      repo.update_attributes(settings: { 'build_pushes' => true })
      patch("/v3/repo/#{repo.id}/setting/build_pushes", JSON.dump('setting.value' => false), json_headers.merge(auth_headers))
      get("/v3/repo/#{repo.id}/setting/build_pushes", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => true },
        'name' => 'build_pushes',
        'value' => false
      )
    end
  end
end