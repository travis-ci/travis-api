describe Travis::API::V3::Services::Repository::Update, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:auth_headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
  let(:env_var) { { id: 'abc', name: 'FOO', value: Travis::Settings::EncryptedValue.new('bar'), public: true, branch: 'foo', repository_id: repo.id } }

  before { Travis.config.applications = { app: { full_access: true, token: '12345' } } }
  after  { Travis.config.applications = {} }

  describe "not authenticated" do
    before  { patch("/v3/repo/#{repo.id}", com_id: 1) }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end

  describe "authenticated" do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal app:12345" } }
    before { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 200 }
    example { expect(repo.reload.com_id).to eq 1 }
  end

  describe "authenticated, missing repo" do
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal app:12345" } }
    before { patch("/v3/repo/9999999999", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end

  describe "authenticated as a user" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}" }}
    before        { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to be == {
      "@type"         => "error",
      "error_type"    => "insufficient_access",
      "error_message" => "forbidden"
    }}
  end

  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal app:12345" } }

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrating") }
      before { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe "repo migrating" do
      before { repo.update_attributes(migration_status: "migrated") }
      before { patch("/v3/repo/#{repo.id}", { com_id: 1 }, headers) }

      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end

    describe 'existing repo, existing env vars' do
      before do
        repo.update_attributes(settings: { env_vars: [env_var] })
        get("/v3/repo/#{repo.id}/env_vars", {}, auth_headers)
      end
      
      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'env_vars',
          '@href' => "/v3/repo/#{repo.id}/env_vars",
          '@representation' => 'standard',
          'env_vars' => [
            {
              '@type' => 'env_var',
              '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
              '@representation' => 'standard',
              '@permissions' => { 'read' => true, 'write' => false },
              'id' => env_var[:id],
              'name' => env_var[:name],
              'value' => env_var[:value].decrypt,
              'public' => env_var[:public],
              'branch' => env_var[:branch]
            }
          ]
        )
      end
    end

    describe 'existing repo, existing env var, owner changed' do
      before do
        repo.update_attributes(settings: { env_vars: [env_var] })
      
        repo.owner_name = 'newowner'
        repo.save
        
        get("/v3/repo/#{repo.id}/env_vars", {}, auth_headers)
      end
  
      example { expect(last_response.status).to eq(200) }
      example do
        expect(JSON.load(body)).to eq(
          '@type' => 'env_vars',
          '@href' => "/v3/repo/#{repo.id}/env_vars",
          '@representation' => 'standard',
          'env_vars' => [
            {
              '@type' => 'env_var',
              '@href' => "/v3/repo/#{repo.id}/env_var/#{env_var[:id]}",
              '@representation' => 'standard',
              '@permissions' => { 'read' => true, 'write' => false },
              'id' => env_var[:id],
              'name' => env_var[:name],
              'value' => '',
              'public' => env_var[:public],
              'branch' => env_var[:branch]
            }
          ]
        )
      end
    end
  end
end
