describe Travis::API::V3::Services::UserSettings::Find, set_app: true do
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

  describe 'authenticated, existing repo, repo has no settings, return defaults' do
    before { get("/v3/repo/#{repo.id}/settings", {}, auth_headers) }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'user_settings',
        '@href' => '/v3/repo/1/settings',
        '@representation' => 'standard',
        'user_settings' => [
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', 'name' => 'builds_only_with_travis_yml', 'value' => false },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/build_pushes", '@representation' => 'standard', 'name' => 'build_pushes', 'value' => true },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests", '@representation' => 'standard', 'name' => 'build_pull_requests', 'value' => true },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds", '@representation' => 'standard', 'name' => 'maximum_number_of_builds', 'value' => 0 }
        ]
      )
    end
  end

  describe 'authenticated, existing repo, repo has some settings' do
    before do
      repo.update_attributes(settings: JSON.dump('build_pushes' => false))
      get("/v3/repo/#{repo.id}/settings", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'user_settings',
        '@href' => '/v3/repo/1/settings',
        '@representation' => 'standard',
        'user_settings' => [
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/builds_only_with_travis_yml", '@representation' => 'standard', 'name' => 'builds_only_with_travis_yml', 'value' => false },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/build_pushes", '@representation' => 'standard', 'name' => 'build_pushes', 'value' => false },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/build_pull_requests", '@representation' => 'standard', 'name' => 'build_pull_requests', 'value' => true },
          { '@type' => 'user_setting','@href' => "/v3/repo/#{repo.id}/setting/maximum_number_of_builds", '@representation' => 'standard', 'name' => 'maximum_number_of_builds', 'value' => 0 }
        ]
      )
    end
  end
end
