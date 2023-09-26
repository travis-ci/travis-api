describe Travis::API::V3::Services::Repository::Activate, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }

  let(:authorization) { { 'permissions' => ['repository_state_update', 'repository_build_create', 'repository_settings_create', 'repository_settings_update', 'repository_cache_view', 'repository_cache_delete', 'repository_settings_delete', 'repository_log_view', 'repository_log_delete', 'repository_build_cancel', 'repository_build_debug', 'repository_build_restart', 'repository_settings_read', 'repository_scans_view'] } }

  let(:authorization_role) { { 'roles' => ['repository_admin'] } }

  before { stub_request(:get, %r((.+)/permissions/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization)) }
  before { stub_request(:get, %r((.+)/roles/repo/(.+))).to_return(status: 200, body: JSON.generate(authorization_role)) }
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    repo.update!(active: false)
  end
  describe "not authenticated" do
    let(:authorization) { { 'permissions' => [] } }
    before  { post("/v3/repo/#{repo.id}/activate")      }
    example { expect(last_response.status).to be == 403 }
    example { expect(JSON.load(body)).to      be ==     {
      "@type"         => "error",
      "error_type"    => "login_required",
      "error_message" => "login required"
    }}
  end
  shared_examples 'repository activation' do
    describe "missing repo, authenticated" do
      before        { post("/v3/repo/9999999999/activate", {}, headers)                 }
      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "repository not found (or insufficient access)",
        "resource_type" => "repository"
      }}
    end
    describe "existing repository, push access" do
      before { Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, pull: true, push: true) }
      around do |ex|
        Travis.config.service_hook_url = 'https://url.of.listener.something'
        ex.run
        Travis.config.service_hook_url = nil
      end
      context 'request' do
        let!(:request) do
          stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
            .to_return(
              status: 200,
              body: nil,
            )
        end
        example do
          post("/v3/repo/#{repo.id}/activate", {}, headers)
          expect(request).to have_been_made
        end
      end
    end
  end
  context 'with user auth' do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) {{ 'HTTP_AUTHORIZATION' => "token #{token}"                        }}
    it_behaves_like 'repository activation'
    describe "existing repository, no push access" do
      let(:authorization) { { 'permissions' => [] } }
      before        { post("/v3/repo/#{repo.id}/activate", {}, headers)                 }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body).to_s).to include(
        "@type",
        "error_type",
        "insufficient_access",
        "error_message",
        "operation requires activate access to repository",
        "resource_type",
        "repository",
        "permission",
        "activate"
      )}
    end
    describe "private repository, no access" do
      before        { repo.update_attribute(:private, true)                             }
      before        { post("/v3/repo/#{repo.id}/activate", {}, headers)                 }
      after         { repo.update_attribute(:private, false)                            }
      example { expect(last_response.status).to be == 404 }
      example { expect(JSON.load(body)).to      be ==     {
        "@type"         => "error",
        "error_type"    => "not_found",
        "error_message" => "repository not found (or insufficient access)",
        "resource_type" => "repository"
      }}
    end

    context 'when activating a perforce repo' do
      let!(:permission) { FactoryBot.create :permission, user_id: repo.owner_id, repository_id: repo.id, admin: true, pull: true, push: true }
      let!(:hook_request) do
        stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      let!(:group_request) do
        stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/perforce_groups?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      let!(:ticket_request) do
        stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/perforce_ticket?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end

      before { repo.update(server_type: 'perforce') }

      it 'creates a perforce group and sets a perforce ticket' do
        post("/v3/repo/#{repo.id}/activate", {}, headers)
        expect(last_response.status).to eq(200)
        expect(group_request).to have_been_made
        expect(ticket_request).to have_been_made
      end
    end

    context 'when activating a private subversion repo' do
      let!(:permission) { FactoryBot.create :permission, user_id: repo.owner_id, repository_id: repo.id, admin: true, pull: true, push: true }
      let!(:hook_request) do
        stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/hook?user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end
      let!(:key_request) do
        stub_request(:post, "http://vcsfake.travis-ci.com/repos/#{repo.id}/keys?read_only=false&user_id=#{repo.owner_id}")
          .to_return(
            status: 200,
            body: nil,
          )
      end

      before { repo.update(private: true, server_type: 'subversion') }

      it 'activates repository' do
        expect do
          post("/v3/repo/#{repo.id}/activate", {}, headers)
        end.to change(Travis::API::V3::Models::Audit, :count).by(1)
        expect(Travis::API::V3::Models::Audit.last.source_changes).to eq('active' => [false, true])
        expect(last_response.status).to eq(200)
      end

      context 'when repository does not have a key' do
        before { repo.key.delete }

        it 'generates a key' do
          post("/v3/repo/#{repo.id}/activate", {}, headers)
          expect(repo.reload.key).to be_present
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
  context 'with internal auth' do
    let(:internal_token) { 'FOO' }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "internal admin:#{internal_token}" } }
    around do |ex|
      apps = Travis.config.applications
      Travis.config.applications = { 'admin' => { token: internal_token, full_access: true }}
      ex.run
      Travis.config.applications = apps
    end
    it_behaves_like 'repository activation'
  end
  context do
    let(:token)   { Travis::Api::App::AccessToken.create(user: repo.owner, app_id: 1) }
    let(:headers) { { 'HTTP_AUTHORIZATION' => "token #{token}" } }
    before do
      Travis.config.host = 'http://travis-ci.org'
      Travis::API::V3::Models::Permission.create(repository: repo, user: repo.owner, admin: true, push: true, pull: true)
    end
    after do
      Travis.config.host = 'http://travis-ci.com'
    end
    describe "repo migrating" do
      before { repo.update(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/activate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
    describe "repo migrated" do
      before { repo.update(migration_status: "migrated") }
      before { post("/v3/repo/#{repo.id}/activate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
  end
end
