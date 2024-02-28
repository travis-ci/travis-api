describe Travis::API::V3::Services::UserSetting::Update, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first_or_create }
  let(:other_user) { FactoryBot.create(:user) }
  let(:token) { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
  let(:other_token) { Travis::Api::App::AccessToken.create(user: other_user, app_id: 2) }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  let(:old_params) { JSON.dump('setting.value' => false) }
  let(:new_params) { JSON.dump('setting.value' => false) }

  let(:authorization) { { 'permissions' => [ 'repository_settings_read'] } }

  before { stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }

  describe 'not authenticated' do
    before do
      patch("/v3/repo/#{repo.id}/setting/build_pushes", new_params, json_headers)
    end

    example { expect(last_response.status).to eq(403) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_type' => 'login_required',
        'error_message' => 'login required'
      )
    end
  end

  describe 'authenticated, missing repo' do
    before do
      patch('/v3/repo/9999999999/setting/build_pushes', new_params, json_headers.merge(auth_headers))
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

  shared_examples 'successful patch' do
    let(:authorization) { { 'permissions' => [ 'repository_settings_read', 'repository_settings_create'] } }
    example { expect(last_response.status).to eq(200) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'setting',
        '@representation' => 'standard',
        '@permissions' => { 'read' => true, 'write' => true },
        '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",
        'name' => 'build_pushes',
        'value' => false
      )
    end
    example 'value is persisted' do
      expect(repo.reload.user_settings.build_pushes).to eq false
    end
    example 'does not clobber other things in the settings hash' do
      expect(repo.reload.settings['env_vars']).to eq(['something'])
    end
    example 'audit is created' do
      expect(Travis::API::V3::Models::Audit.last.source_id).to eq(repo.id)
      expect(Travis::API::V3::Models::Audit.last.source_type).to eq('Repository')
      expect(Travis::API::V3::Models::Audit.last.source_changes).to eq({"settings"=>{"build_pushes"=>{"after"=>false, "before"=>true}}})      
    end
  end

  describe 'authenticated, existing repo, old params' do
    before do
      repo.update_attribute(:settings, JSON.dump('env_vars' => ['something']))
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      patch("/v3/repo/#{repo.id}/setting/build_pushes", old_params, json_headers.merge(auth_headers))
    end
    include_examples 'successful patch'
  end

  describe 'authenticated, existing repo, new params' do
    before do
      repo.update_attribute(:settings, JSON.dump('env_vars' => ['something']))
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
      patch("/v3/repo/#{repo.id}/setting/build_pushes", new_params, json_headers.merge(auth_headers))
    end
    include_examples 'successful patch'
  end

  describe 'authenticated, existing repo, user does not have correct permissions' do
    before do
      patch("/v3/repo/#{repo.id}/setting/build_pushes", new_params, json_headers.merge('HTTP_AUTHORIZATION' => "token #{other_token}"))
    end

    example { expect(last_response.status).to eq(403) }
    example do
      expect(JSON.load(body)).to eq(
        '@type' => 'error',
        'error_type' => 'insufficient_access',
        'error_message' => 'operation requires write access to user_setting',
        'permission' => 'write',
        'resource_type' => 'user_setting',
        'user_setting' => {
          '@type' => 'setting',
          '@href' => "/v3/repo/#{repo.id}/setting/build_pushes",
          '@representation' => 'minimal',
          'name' => 'build_pushes',
          'value' => true
        }
      )
    end
  end

  context do
    before do
      repo.update_attribute(:settings, JSON.dump('env_vars' => ['something']))
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, push: true)
    end
 
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before {
        patch("/v3/repo/#{repo.id}/setting/build_pushes", new_params, json_headers.merge(auth_headers))
      }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before {
        patch("/v3/repo/#{repo.id}/setting/build_pushes", new_params, json_headers.merge(auth_headers))
      }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end

end
