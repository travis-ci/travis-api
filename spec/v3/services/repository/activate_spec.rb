describe Travis::API::V3::Services::Repository::Activate, set_app: true do
  let(:repo) { Travis::API::V3::Models::Repository.where(owner_name: 'svenfuchs', name: 'minimal').first }
  before do
    Travis.config.vcs.url = 'http://vcsfake.travis-ci.com'
    Travis.config.vcs.token = 'vcs-token'
    repo.update_attributes!(active: false)
    stub_request(:get, %r((.+)/repo/(.+))).to_return(status: 401)
  end
  describe "not authenticated" do
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
      before { repo.update_attributes(migration_status: "migrating") }
      before { post("/v3/repo/#{repo.id}/activate", {}, headers) }
      example { expect(last_response.status).to be == 403 }
      example { expect(JSON.load(body)).to be == {
        "@type"         => "error",
        "error_type"    => "repo_migrated",
        "error_message" => "This repository has been migrated to travis-ci.com. Modifications to repositories, builds, and jobs are disabled on travis-ci.org. If you have any questions please contact us at support@travis-ci.com"
      }}
    end
    describe "repo migrated" do
      before { repo.update_attributes(migration_status: "migrated") }
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
