describe Travis::API::V3::Services::UserSettings::ForRepository, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

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
    before { get("/v3/repo/#{repo.id}/settings", {}, auth_headers) }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'settings',
        '@href' => "/v3/repo/#{repo.id}/settings",
        '@representation' => 'standard',
        'settings' => [
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', 'name' => 'builds_only_with_travis_yml', 'value' => false },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/build_pushes", '@representation' => 'standard', 'name' => 'build_pushes', 'value' => true },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests", '@representation' => 'standard', 'name' => 'build_pull_requests', 'value' => true },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds", '@representation' => 'standard', 'name' => 'maximum_number_of_builds', 'value' => 0 },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pushes", '@representation' => 'standard', 'name' => 'auto_cancel_pushes', 'value' => false },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pull_requests", '@representation' => 'standard', 'name' => 'auto_cancel_pull_requests', 'value' => false },
        ]
      )
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
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', 'name' => 'builds_only_with_travis_yml', 'value' => false },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/build_pushes", '@representation' => 'standard', 'name' => 'build_pushes', 'value' => false },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests", '@representation' => 'standard', 'name' => 'build_pull_requests', 'value' => true },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds", '@representation' => 'standard', 'name' => 'maximum_number_of_builds', 'value' => 0 },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pushes", '@representation' => 'standard', 'name' => 'auto_cancel_pushes', 'value' => false },
          { '@type' => 'setting', '@permissions' => { 'read' => true, 'write' => false }, '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pull_requests", '@representation' => 'standard', 'name' => 'auto_cancel_pull_requests', 'value' => false },
        ]
      )
    end
  end
end
