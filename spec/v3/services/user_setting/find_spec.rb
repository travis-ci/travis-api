describe Travis::API::V3::Services::UserSetting::Find, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  describe 'not authenticated' do
    before { get("/v3/repo/#{repo.id}/setting/build_pushes") }
    include_examples 'not authenticated'
  end

  describe 'authenticated as wrong user' do
    let(:other_user) { FactoryGirl.create(:user) }
    let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 1) }

    before do
      repo.update_attributes(private: true)
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
      repo.update_attributes(settings: JSON.dump('build_pushes' => false))
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
end
