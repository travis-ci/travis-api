describe Travis::API::V3::Services::UserSetting::Find, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  let(:authorization) { { 'permissions' => ['repository_settings_read'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/setting/build_pushes") }
    include_examples 'not authenticated'
  end

  describe 'authenticated as wrong user' do
    let(:other_user) { FactoryBot.create(:user) }
    let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }

    before do
      repo.update(private: true)
      get("/v3/repo/#{repo.id}/setting/build_pushes", {}, { 'HTTP_AUTHORIZATION' => "token #{other_token}" })
    end

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

  describe 'authenticated, missing repo' do
    before { get('/v3/repo/9999999999/setting/build_pushes', {}, auth_headers) }

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

  describe 'authenticated, existing repo, setting missing, return default' do
    before { get("/v3/repo/#{repo.id}/setting/build_pushes", {}, auth_headers) }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => false },
        '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",
        'name' => 'build_pushes',
        'value' => true
      )
    end
  end

  describe 'authenticated, existing repo, setting found' do
    before do
      repo.update(settings: { 'build_pushes' => false })
      get("/v3/repo/#{repo.id}/setting/build_pushes", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => false },
        '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",
        'name' => 'build_pushes',
        'value' => false
      )
    end
  end

  describe 'authenticated, existing repo, default auto cancel setting' do
    before do
      ENV['AUTO_CANCEL_DEFAULT'] = 'true'
      get("/v3/repo/#{repo.id}/setting/auto_cancel_pushes", {}, auth_headers)
    end
    after do
      ENV['AUTO_CANCEL_DEFAULT'] = nil
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => false },
        '@href' => "/v3/repo/#{repo.id}/setting/auto_cancel_pushes",
        'name' => 'auto_cancel_pushes',
        'value' => true
      )
    end
  end

  describe 'authenticated, existing repo, default share_encrypted_env_with_forks setting' do
    before do
      get("/v3/repo/#{repo.id}/setting/share_encrypted_env_with_forks", {}, auth_headers)
    end

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => false },
        '@href' => "/v3/repo/#{repo.id}/setting/share_encrypted_env_with_forks",
        'name' => 'share_encrypted_env_with_forks',
        'value' => false
      )
    end
  end

  describe 'authenticated, existing repo, default share_ssh_keys_with_forks setting' do
    let(:created_at) { Date.parse('2021-09-01') }

    before do
      ENV['IBM_REPO_SWITCHES_DATE'] = '2021-10-01'
      repo.update(created_at: created_at)
      get("/v3/repo/#{repo.id}/setting/share_ssh_keys_with_forks", {}, auth_headers)
    end

    after { ENV['IBM_REPO_SWITCHES_DATE'] = nil }

    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => false },
        '@href' => "/v3/repo/#{repo.id}/setting/share_ssh_keys_with_forks",
        'name' => 'share_ssh_keys_with_forks',
        'value' => true
      )
    end

    context 'when repo is new' do
      let(:created_at) { Date.parse('2021-11-01') }

      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'setting',
          '@representation' => 'standard',
          '@permissions' => { 'read' => true, 'write' => false },
          '@href' => "/v3/repo/#{repo.id}/setting/share_ssh_keys_with_forks",
          'name' => 'share_ssh_keys_with_forks',
          'value' => false
        )
      end
    end
  end
end
