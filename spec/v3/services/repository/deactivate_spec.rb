describe Travis::API::V3::Services::Repository::Deactivate, set_app: true do
  let(:repo)  { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  let(:keys) { [] }
  let!(:keys_request) do
    stub_request(:get, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys?user_id=#{repo.owner_id}")
      .to_return(
        status: 200,
        body: JSON.dump(keys),
      )
  end

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  let(:authorization_role) { { 'roles' => ['repository_admin'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization_role)) }

  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    repo.update!(active: true)
  end
  describe "not authenticated" do
    before  { post("/v3/repo/#{repo.id}/deactivate")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end
  describe "missing repo, authenticated" do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    before        { post("/v3/repo/9999999999/deactivate", {}, headers)                 }
    example { expect(last_response.status).to be == 404 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "not_found",
      "error_message" => "repository not found (or insufficient access)",
      "resource_type" => "repository"
    }}
  end
  shared_examples 'repository deactivation' do
    describe 'existing repository, wrong access' do
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, pull: true) }
      before {
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      }
      let(:authorization) { { 'permissions' => [] } }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
      example 'is success' do
        expect(last_response.status).to eq 403
        expect(JSON.load(body)).to include(
          '@type' => 'error',
          'error_type' => 'insufficient_access'
        )
      end
    end
    describe "existing repository, admin and push access" do
      let!(:request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true) 
      }
      around do |ex|
        Travis.config.service_hook_url = 'https://url.of.listener.something'
        ex.run
        Travis.config.service_hook_url = nil
      end
      example 'creates webhook' do
        post("/v3/repo/#{repo.id}/deactivate", {}, headers)
        expect(request).to have_been_made
        expect(last_response.status).to eq 200
        expect(JSON.load(body)).to include(
          '@type' => 'repository',
          'active' => false
        )
      end
    end
  end
  context 'user auth' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    it_behaves_like 'repository deactivation'
    describe "existing repository, no push access" do
      let(:authorization) { { 'permissions' => [] } }
      before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error_type",
        "insufficient_access",
        "error_message",
        "operation requires deactivate access to repository",
        "resource_type",
        "repository",
        "permission",
        "deactivate")
      }
    end
    describe "private repository, no access" do
      before        { repo.update_attribute(:private, true)                             }
      before        { post("/v3/repo/#{repo.id}/deactivate", {}, headers)                 }
      after         { repo.update_attribute(:private, false)                            }
      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "repository not found (or insufficient access)",
        "resource_type" => "repository"
      }}
    end

    context 'when deactivating a perforce repo' do
      let!(:permission) { FactoryBot.create :permission, user_id: repo.owner_id, repository_id: repo.id, admin: true, pull: true, push: true }
      let!(:hook_request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      let!(:group_request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/perforce_groups?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end

      before { repo.update(server_type: 'perforce') }

      it 'deletes the perforce group' do
        post("/v3/repo/#{repo.id}/deactivate", {}, headers)
        expect(last_response.status).to eq(200)
        expect(group_request).to have_been_made
      end
    end

    context 'when deactivating a private subversion repo' do
      let!(:permission) { FactoryBot.create :permission, user_id: repo.owner_id, repository_id: repo.id, admin: true, pull: true, push: true }
      let(:fingerprint) { PrivateKey.new(repo.key.private_key).fingerprint.gsub(':', '') }
      let(:key) do
        {
          id: 1,
          fingerprint: fingerprint
        }
      end
      let!(:hook_request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      let(:keys) { [key] }
      let!(:key_request) do
        stub_request(:delete, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys/#{key[:id]}?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end

      before { repo.update(private: true, server_type: 'subversion') }

      it 'deactivates repository' do
        expect do
          post("/v3/repo/#{repo.id}/deactivate", {}, headers)
        end.to change(Travis::API::V3::Models::Audit, :count).by(1)
        expect(Travis::API::V3::Models::Audit.last.source_changes).to eq('active' => [true, false])
        expect(last_response.status).to eq(200)
      end
    end
  end
  context 'internal auth' do
    let(:internal_token) { 'FOO' }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal admin:#{internal_token}" } }
    around do |ex|
      apps = Travis.config.applications
      Travis.config.applications = { 'admin' => { token: internal_token, full_access: true }}
      ex.run
      Travis.config.applications = apps
    end
    before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
    example 'is success' do
      expect(last_response.status).to eq 403
      expect(JSON.load(body)).to include(
        '@type' => 'error',
        'error_type' => 'admin_access_required'
      )
    end
  end
  describe "existing repository, push access"
  # as this requires a call to github, and stubbing this request has proven difficult,
  # this test has been omitted for now
  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true, pull: true) }
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
    describe "repo migrated" do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/deactivate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
